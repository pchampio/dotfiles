/*
 * tmux_update_statusbar — client/server statusbar tab distributor.
 *
 * Distributes window tabs across bottom panes left-to-right.
 * A long-running server debounces rapid hook invocations: each event resets
 * a 50 ms timer; only the last event in a burst triggers the actual recompute.
 *
 * Usage:
 *   tmux_update_statusbar          client: notify server (auto-starts if needed)
 *   tmux_update_statusbar --server run server in foreground (internal)
 *   tmux_update_statusbar --stop   tell a running server to exit
 *
 * Build:
 *   cc -O2 -o tmux_update_statusbar tmux_update_statusbar.c
 */

#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

/* ── Colour constants (must match tmux.conf) ─────────────────────────── */
#define BG        "#fbf3db"
#define IDX_FG_I  "colour8"
#define IDX_BG_I  "colour59"
#define NAME_FG_I "colour58"
#define NAME_BG_I "colour188"
#define IDX_FG_A  "colour7"
#define IDX_BG_A  "colour124"
#define NAME_FG_A "colour59"
#define NAME_BG_A "colour188"

/* ── Tuning constants ────────────────────────────────────────────────── */
#define BORDER_OVERHEAD  2
#define MAX_CMD_BYTES    8192
#define MAX_WINDOWS      256
#define MAX_PANES        1024
#define BUF_SZ           (256 * 1024)

#define DEBOUNCE_MS      50     /* ms: each request resets this timer; */
                                /* only the last request in a burst    */
                                /* triggers the actual recompute.      */
#define IDLE_TIMEOUT_MS  60000  /* exit server after 60 s with no work */

/* ── Data types ──────────────────────────────────────────────────────── */
typedef struct {
    int  idx;
    char name[256];
    int  zoomed;
    int  synced;
    char wid[32];   /* window id  e.g. @1 */
    char sid[32];   /* session id e.g. $0 */
} Win;

typedef struct {
    char id[32];    /* pane id e.g. %1 */
    int  at_bottom;
    int  width;
    int  left;
    char wid[32];   /* owning window id */
    int  active;
} Pane;

typedef struct {
    char sid[32];
    int  tabs[MAX_WINDOWS];   /* indices into wins[] */
    int  ntabs;
} Session;

/* ── Globals ─────────────────────────────────────────────────────────── */
static Win     wins[MAX_WINDOWS];
static int     nwin;
static Pane    panes[MAX_PANES];
static int     npane;
static int     tab_width[MAX_WINDOWS];
static char    tab_str[MAX_WINDOWS][2048];
static Session sessions[MAX_WINDOWS];
static int     nsess;
static char    cmd_buf[BUF_SZ];
static int     cmd_len, cmd_count;
static char    sock_path[256];

/* ── Helpers ─────────────────────────────────────────────────────────── */

/* Socket path: unique per uid + tmux-server PID (from $TMUX) */
static void make_sock_path(void) {
    int pid = 0;
    const char *t = getenv("TMUX");
    if (t) { const char *c = strchr(t, ','); if (c) pid = atoi(c + 1); }
    if (pid > 0)
        snprintf(sock_path, sizeof sock_path,
                 "/tmp/tmux-statusbar-%d-%d.sock", getuid(), pid);
    else
        snprintf(sock_path, sizeof sock_path,
                 "/tmp/tmux-statusbar-%d.sock", getuid());
}

static int digits(int n) {
    if (n < 0) n = -n;
    int d = 1; while (n >= 10) { d++; n /= 10; } return d;
}

/* ── Tmux query / parse ──────────────────────────────────────────────── */
static char *tmux_query(void) {
    static char buf[BUF_SZ];
    FILE *fp = popen(
        "tmux list-windows -a -F "
          "'W\t#{window_index}\t#{window_name}\t#{window_zoomed_flag}"
          "\t#{pane_synchronized}\t#{window_id}\t#{session_id}' \\; "
        "list-panes -a -F "
          "'P\t#{pane_id}\t#{pane_at_bottom}\t#{pane_width}"
          "\t#{pane_left}\t#{window_id}\t#{pane_active}' "
        "2>/dev/null", "r");
    if (!fp) return NULL;
    size_t tot = 0;
    while (tot < sizeof buf - 1) {
        size_t n = fread(buf + tot, 1, sizeof buf - 1 - tot, fp);
        if (!n) break;
        tot += n;
    }
    buf[tot] = '\0';
    pclose(fp);
    return tot ? buf : NULL;
}

static void parse_data(char *data) {
    nwin = npane = 0;
    char *line, *sv;
    for (line = strtok_r(data, "\n", &sv); line;
         line = strtok_r(NULL, "\n", &sv)) {
        if (line[0] == 'W' && line[1] == '\t' && nwin < MAX_WINDOWS) {
            Win *w = &wins[nwin];
            char *p = line + 2, *f[6]; int fi = 0;
            for (char *tk = strtok_r(p, "\t", &p); tk && fi < 6;
                 tk = strtok_r(NULL, "\t", &p))
                f[fi++] = tk;
            if (fi < 6) continue;
            w->idx    = atoi(f[0]);
            snprintf(w->name, sizeof w->name, "%s", f[1]);
            w->zoomed = atoi(f[2]);
            w->synced = atoi(f[3]);
            snprintf(w->wid, sizeof w->wid, "%s", f[4]);
            snprintf(w->sid, sizeof w->sid, "%s", f[5]);
            nwin++;
        } else if (line[0] == 'P' && line[1] == '\t' && npane < MAX_PANES) {
            Pane *pp = &panes[npane];
            char *p = line + 2, *f[6]; int fi = 0;
            for (char *tk = strtok_r(p, "\t", &p); tk && fi < 6;
                 tk = strtok_r(NULL, "\t", &p))
                f[fi++] = tk;
            if (fi < 6) continue;
            snprintf(pp->id,  sizeof pp->id,  "%s", f[0]);
            pp->at_bottom = atoi(f[1]);
            pp->width     = atoi(f[2]);
            pp->left      = atoi(f[3]);
            snprintf(pp->wid, sizeof pp->wid, "%s", f[4]);
            pp->active    = atoi(f[5]);
            npane++;
        }
    }
}

/* ── Tab format strings ──────────────────────────────────────────────── */
static void build_tabs(void) {
    for (int i = 0; i < nwin; i++) {
        Win *w = &wins[i];
        char flags[32] = ""; int flags_w = 0;
        if (w->zoomed) { strcat(flags, "🔍 "); flags_w += 3; }
        if (w->synced) { strcat(flags, "⇔ ");  flags_w += 2; }
        tab_width[i] = 5 + digits(w->idx) + (int)strlen(w->name) + flags_w;
        snprintf(tab_str[i], sizeof tab_str[i],
            "#[bg=" BG "] "
            "#{?#{==:%d,#{window_index}},"
                "#[fg=" IDX_FG_A "#,bg=" IDX_BG_A "],"
                "#[fg=" IDX_FG_I "#,bg=" IDX_BG_I "]"
            "} %d "
            "#{?#{==:%d,#{window_index}},"
                "#[fg=" NAME_FG_A "#,bg=" NAME_BG_A "],"
                "#[fg=" NAME_FG_I "#,bg=" NAME_BG_I "]"
            "} %s %s",
            w->idx, w->idx, w->idx, w->name, flags);
    }
}

/* ── Session grouping ────────────────────────────────────────────────── */
static void build_sessions(void) {
    nsess = 0;
    for (int i = 0; i < nwin; i++) {
        int s = -1;
        for (int j = 0; j < nsess; j++)
            if (strcmp(sessions[j].sid, wins[i].sid) == 0) { s = j; break; }
        if (s < 0) {
            s = nsess++;
            snprintf(sessions[s].sid, sizeof sessions[s].sid, "%s", wins[i].sid);
            sessions[s].ntabs = 0;
        }
        sessions[s].tabs[sessions[s].ntabs++] = i;
    }
}

static const Session *session_for_wid(const char *wid) {
    for (int i = 0; i < nwin; i++)
        if (strcmp(wins[i].wid, wid) == 0)
            for (int s = 0; s < nsess; s++)
                if (strcmp(sessions[s].sid, wins[i].sid) == 0)
                    return &sessions[s];
    return NULL;
}

/* ── Batched tmux set-option ─────────────────────────────────────────── */
static void cmd_init(void) {
    cmd_len = snprintf(cmd_buf, sizeof cmd_buf, "tmux");
    cmd_count = 0;
}

static void cmd_flush(void) {
    if (cmd_count > 0) { (void)!system(cmd_buf); cmd_init(); }
}

static void cmd_queue(const char *pid, const char *val) {
    int entry = 40 + (int)strlen(pid) + (int)strlen(val);
    if (cmd_len + entry > MAX_CMD_BYTES && cmd_count > 0) cmd_flush();
    int n;
    if (cmd_count > 0)
        n = snprintf(cmd_buf + cmd_len, sizeof cmd_buf - cmd_len,
                     " \\; set-option -p -t '%s' @pane_tabs '%s'", pid, val);
    else
        n = snprintf(cmd_buf + cmd_len, sizeof cmd_buf - cmd_len,
                     " set-option -p -t '%s' @pane_tabs '%s'", pid, val);
    cmd_len += n; cmd_count++;
}

/* ── Fill a pane with as many session tabs as fit ────────────────────── */
static void build_content(char *out, size_t outsz, int avail,
                          const Session *sess, int *cursor) {
    out[0] = '\0'; int pos = 0;
    while (*cursor < sess->ntabs) {
        int ti = sess->tabs[*cursor];
        int tw = tab_width[ti];
        if (tw > avail) break;
        int n = snprintf(out + pos, outsz - pos, "%s", tab_str[ti]);
        pos += n; avail -= tw; (*cursor)++;
    }
    if (pos > 0) snprintf(out + pos, outsz - pos, "#[bg=" BG "]#[default]");
}

static int is_zoomed(const char *wid) {
    for (int i = 0; i < nwin; i++)
        if (strcmp(wins[i].wid, wid) == 0) return wins[i].zoomed;
    return 0;
}

/* ── Core update — returns 0 on success, -1 if tmux is gone ─────────── */
static int do_update(void) {
    char *data = tmux_query();
    if (!data) return -1;
    parse_data(data);
    if (!nwin || !npane) return -1;
    build_tabs();
    build_sessions();
    cmd_init();

    /* unique window ids from pane list */
    char uwids[MAX_PANES][32]; int nuw = 0;
    for (int i = 0; i < npane; i++) {
        int found = 0;
        for (int j = 0; j < nuw; j++)
            if (strcmp(uwids[j], panes[i].wid) == 0) { found = 1; break; }
        if (!found) snprintf(uwids[nuw++], 32, "%s", panes[i].wid);
    }

    static char content[BUF_SZ];

    for (int u = 0; u < nuw; u++) {
        const char *wid = uwids[u];
        const Session *sess = session_for_wid(wid);
        if (!sess) continue;
        int zoomed = is_zoomed(wid);

        if (zoomed) {
            for (int i = 0; i < npane; i++) {
                if (strcmp(panes[i].wid, wid)) continue;
                if (panes[i].active) {
                    int avail = panes[i].width - BORDER_OVERHEAD, cur = 0;
                    build_content(content, sizeof content, avail, sess, &cur);
                    cmd_queue(panes[i].id, content);
                } else {
                    cmd_queue(panes[i].id, "");
                }
            }
            continue;
        }

        int bottom[MAX_PANES], nb = 0, nonbot[MAX_PANES], nn = 0;
        for (int i = 0; i < npane; i++) {
            if (strcmp(panes[i].wid, wid)) continue;
            if (panes[i].at_bottom) bottom[nb++] = i; else nonbot[nn++] = i;
        }

        /* sort bottom panes by x position */
        for (int i = 1; i < nb; i++) {
            int key = bottom[i], j = i - 1;
            while (j >= 0 && panes[bottom[j]].left > panes[key].left)
                { bottom[j+1] = bottom[j]; j--; }
            bottom[j+1] = key;
        }

        int tab_cursor = 0;
        for (int b = 0; b < nb; b++) {
            int pi = bottom[b], avail = panes[pi].width - BORDER_OVERHEAD;
            build_content(content, sizeof content, avail, sess, &tab_cursor);
            cmd_queue(panes[pi].id, content);
        }
        for (int n = 0; n < nn; n++) cmd_queue(panes[nonbot[n]].id, "");
    }

    cmd_flush();
    return 0;
}

/* ═══════════════════════════════════════════════════════════════════════
 *  Server
 * ═══════════════════════════════════════════════════════════════════════ */
static volatile sig_atomic_t srv_stop;

static void on_signal(int s) { (void)s; srv_stop = 1; }

/* Accept every pending connection.  Returns 1 if a stop was requested. */
static int drain_accepts(int lfd) {
    for (;;) {
        int fd = accept(lfd, NULL, NULL);
        if (fd < 0) break;
        char c;
        if (recv(fd, &c, 1, MSG_DONTWAIT) == 1 && c == 'Q')
            srv_stop = 1;
        close(fd);
    }
    return srv_stop;
}

static int server_main(void) {
    int lfd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (lfd < 0) return 1;
    fcntl(lfd, F_SETFL, fcntl(lfd, F_GETFL) | O_NONBLOCK);

    unlink(sock_path);
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sock_path, sizeof addr.sun_path - 1);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof addr) < 0)
        { close(lfd); return 1; }
    chmod(sock_path, 0700);
    if (listen(lfd, 64) < 0) { close(lfd); unlink(sock_path); return 1; }

    signal(SIGPIPE, SIG_IGN);
    signal(SIGTERM, on_signal);
    signal(SIGINT,  on_signal);

    struct pollfd pfd = { .fd = lfd, .events = POLLIN };
    while (!srv_stop) {
        /* ---- wait for first event ---- */
        int ret = poll(&pfd, 1, IDLE_TIMEOUT_MS);
        if (ret == 0)  break;                        /* idle timeout  */
        if (ret <  0)  { if (errno == EINTR) continue; break; }
        if (drain_accepts(lfd)) break;

        /* ---- debounce: each new event resets the 50 ms timer.
               Only when 50 ms pass with silence do we recompute. ---- */
        while (!srv_stop) {
            ret = poll(&pfd, 1, DEBOUNCE_MS);
            if (ret <= 0) break;                     /* 50 ms silence */
            if (drain_accepts(lfd)) break;
        }
        if (srv_stop) break;

        if (do_update() < 0) break;                  /* tmux gone     */
    }

    close(lfd);
    unlink(sock_path);
    return 0;
}

/* ═══════════════════════════════════════════════════════════════════════
 *  Client
 * ═══════════════════════════════════════════════════════════════════════ */
static int client_connect(void) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    struct sockaddr_un a;
    memset(&a, 0, sizeof a);
    a.sun_family = AF_UNIX;
    strncpy(a.sun_path, sock_path, sizeof a.sun_path - 1);
    if (connect(fd, (struct sockaddr *)&a, sizeof a) < 0) { close(fd); return -1; }
    return fd;
}

static int client_notify(void) {
    /* Fast path: server already running */
    int fd = client_connect();
    if (fd >= 0) { close(fd); return 0; }

    /* Auto-start server as a daemon */
    pid_t p = fork();
    if (p < 0) return 1;
    if (p == 0) {
        setsid();
        int dn = open("/dev/null", O_RDWR);
        if (dn >= 0) { dup2(dn, 0); dup2(dn, 1); dup2(dn, 2);
                        if (dn > 2) close(dn); }
        _exit(server_main());
    }

    /* Wait for server to be ready, then send the first notification */
    for (int i = 0; i < 20; i++) {
        usleep(25000);  /* 25 ms */
        fd = client_connect();
        if (fd >= 0) { close(fd); return 0; }
    }
    return 1;
}

static int client_stop(void) {
    int fd = client_connect();
    if (fd < 0) return 0;               /* not running — nothing to do */
    char q = 'Q';
    (void)!write(fd, &q, 1);
    close(fd);
    return 0;
}

/* ═══════════════════════════════════════════════════════════════════════
 *  main
 * ═══════════════════════════════════════════════════════════════════════ */
int main(int argc, char **argv) {
    make_sock_path();
    if (argc > 1 && strcmp(argv[1], "--server") == 0) return server_main();
    if (argc > 1 && strcmp(argv[1], "--stop")   == 0) return client_stop();
    return client_notify();
}
