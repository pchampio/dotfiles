{
  programs.plasma = {
    shortcuts = {
      "KDE Keyboard Layout Switcher"."Switch keyboard layout to English (US)" = [ ];
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Ctrl+Alt+K";
      "kded5"."Show System Activity" = "Ctrl+Esc";
      "kded5"."display" = ["Display" "Meta+P"];
      "kitty.desktop"."_launch" = "Ctrl+Alt+T";
      "ksmserver"."Lock Session" = ["Screensaver" "Meta+L"];
      "kwin"."Switch to Next Desktop" = "Ctrl+Alt+L";
      "kwin"."Switch to Previous Desktop" = "Ctrl+Alt+H";
      "kwin"."Walk Through Windows" = "Alt+Tab";
      "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Backtab";
      "kwin"."Window Close" = ["Ctrl+Q" "Alt+F4"];
      "kwin"."Window Maximize" = "Meta+K";
      "kwin"."Window Resize" = "Alt+1";
      "org.kde.dolphin.desktop"."_launch" = ["Ctrl+Alt+E" "Meta+E"];
    };
    configFile = {
      kxkbrc = {
        "Layout"."Options" = "caps:escape";
      };
      "kwalletrc"."Wallet"."Enabled" = false;
      "kwalletrc"."Wallet"."First Use" = false;
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
      "baloofilerc"."General"."dbVersion" = 2;
      "baloofilerc"."General"."exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,core-dumps,lost+found";
      "baloofilerc"."General"."exclude filters version" = 8;
      "dolphinrc"."ContextMenu"."ShowAddToPlaces" = false;
      "dolphinrc"."ContextMenu"."ShowCopyLocation" = false;
      "dolphinrc"."ContextMenu"."ShowDuplicateHere" = false;
      "dolphinrc"."ContextMenu"."ShowOpenInNewTab" = false;
      "dolphinrc"."ContextMenu"."ShowOpenInNewWindow" = false;
      "dolphinrc"."ContextMenu"."ShowOpenTerminal" = false;
      "dolphinrc"."ContextMenu"."ShowSortBy" = false;
      "dolphinrc"."ContextMenu"."ShowViewMode" = false;
      "dolphinrc"."General"."ShowZoomSlider" = false;
      "dolphinrc"."IconsMode"."IconSize" = 80;
      "dolphinrc"."IconsMode"."PreviewSize" = 112;
      "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = false;
      "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 22;
      "dolphinrc"."Open-with settings"."CompletionMode" = 1;
      "dolphinrc"."Open-with settings"."History" = "gee,gra,grav,mpv,google,vlc,snap,gravit,gravi";
      "dolphinrc"."PreviewSettings"."Plugins" = "appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,svgthumbnail,ffmpegthumbs";
      "dolphinrc"."SettingsDialog"."DP-1 Height 3264x1836" = 821;
      "dolphinrc"."SettingsDialog"."DP-1 Width 3264x1836" = 1196;
      "dolphinrc"."SettingsDialog"."eDP-1 Height 3840x2160" = 821;
      "dolphinrc"."SettingsDialog"."eDP-1 Width 3840x2160" = 1196;
      "kcminputrc"."Mouse"."X11LibInputXAccelProfileFlat" = false;
      "kcminputrc"."Mouse"."XLbInptPointerAcceleration" = 0.2;
      "kcminputrc"."Mouse"."cursorSize" = 48;
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
    };
  };
}
