#!/usr/bin/env python2

############################################################################
# Copyright (c) 2009   unohu <unohu0@gmail.com> and Contributors           #
#                                                                          #
# Contributors: John Elkins <soulfx@yahoo.com>                             #
#                                                                          #
# Permission to use, copy, modify, and/or distribute this software for any #
# purpose with or without fee is hereby granted, provided that the above   #
# copyright notice and this permission notice appear in all copies.        #
#                                                                          #
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES #
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF         #
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR  #
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   #
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN    #
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF  #
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.           #
#                                                                          #
############################################################################

from __future__ import with_statement
import sys
import os
import commands
import pickle
import ConfigParser
import types
import logging

PROGRAM_NAME = "Simple Window Tiler"
PROGRAM_VERSION = "0.2"
PROGRAM_SOURCE = "http://github.com/soulfx/stiler/tree/grid"

logging.basicConfig(level=logging.WARN)
log = logging.getLogger()
log.name = PROGRAM_NAME

def initconfig():

    rcfile=os.getenv('HOME')+"/.stilerrc"

    configDefaults={
        'BottomPadding':'0',
        'TopPadding': '0',
        'LeftPadding': '0',
        'RightPadding': '0',
        'WinTitle': '21',
        'WinBorder': '1',
        'MwFactor': '0.65',
        'Monitors': '1',
        'GridWidths': '0.33,0.50',
        'WidthAdjustment':'0.0',
        'TempFile': '/tmp/tile_winlist',
        'WindowFilter':'on',
    }

    config=ConfigParser.RawConfigParser(configDefaults)


    if not os.path.exists(rcfile):
    	log.info("writing new config file to "+rcfile)
        cfg=open(rcfile,'w')
        config.write(cfg)
        cfg.close()

    config.read(rcfile)
    return config

def version_option():
    """
    Display program version information
    """
    print "%s %s  <%s>" % (PROGRAM_NAME,PROGRAM_VERSION,PROGRAM_SOURCE)

def v_flag():
    """
    Enable INFO level verbosity
    """
    log.setLevel(logging.INFO)

def vv_flag():
    """
    Enable DEBUG level verbosity
    """
    log.setLevel(logging.DEBUG)

def has_required_programs(program_list):
    """
    Returns true if all the programs in the program_list are on the system
    """

    returnValue = True

    for program in program_list:
        if commands.getstatusoutput("which "+program)[0] != 0:
            log.error(program+" is required by "+PROGRAM_NAME)
            returnValue = False

    return returnValue

def is_valid_window(window):
    """
    Returns True if the given window should be tiled, False otherwise
    """

    if WindowFilter == True:
        window_type = commands.getoutput("xprop -id "+window+" _NET_WM_WINDOW_TYPE | cut -d_ -f10").split("\n")[0]
        window_state = commands.getoutput("xprop -id "+window+" WM_STATE | grep \"window state\" | cut -d: -f2").split("\n")[0].lstrip()

        logging.debug("%s is type %s, state %s" % (window,window_type,window_state))

        if window_type == "UTILITY" or window_type == "DESKTOP" or window_state == "Iconic" or window_type == "DOCK" :
            return False

    return True

def initialize():

    desk_output = commands.getoutput("wmctrl -d").split("\n")
    desk_list = [line.split()[0] for line in desk_output]

    current =  filter(lambda x: x.split()[1] == "*" , desk_output)[0].split()

    desktop = current[0]
    width =  current[8].split("x")[0]
    height =  current[8].split("x")[1]
    orig_x =  current[7].split(",")[0]
    orig_y =  current[7].split(",")[1]

    win_output = commands.getoutput("wmctrl -lG").split("\n")
    win_list = {}

    for desk in desk_list:
        win_list[desk] = map(lambda y: hex(int(y.split()[0],16)) , filter(lambda x: x.split()[1] == desk, win_output ))

    return (desktop,orig_x,orig_y,width,height,win_list)


def get_active_window():
    active = commands.getoutput("xprop -root _NET_ACTIVE_WINDOW | cut -d' ' -f5 | cut -d',' -f1")
    if is_valid_window(active) == True:
    	logging.debug("obtained active window: '"+str(active)+"'")
        return active
    else:
        return 0

def get_window_width_height(window_id):
    """
    return the given window's [width, height]
    """
    return commands.getoutput(" xwininfo -id "+window_id+" | egrep \"Height|Width\" | cut -d: -f2 | tr -d \" \"").split("\n")

def get_window_x_y(windowid):
    """
    return the given window's [x,y] position
    """
    return commands.getoutput("xwininfo -id "+windowid+" | grep 'Corners' | cut -d' ' -f5 | cut -d'+' -f2,3").split("+")

def store(object,file):
    with open(file, 'w') as f:
        pickle.dump(object,f)
    f.close()


def retrieve(file):
    try:
        with open(file,'r+') as f:
            obj = pickle.load(f)
        f.close()
        return(obj)
    except:
        f = open(file,'w')
        f.close
        dict = {}
        return (dict)

def get_width_constant(width, width_constant_array):
    """
    Returns the current closest width constant from the given constant_array and given current width
    """
    return min ( map (lambda y: [abs(y-width),y], width_constant_array))[1]

def get_next_width(current_width,width_array):
    """
    Returns the next width to use based on the given current width, and width constants
    """
    active_width = float(current_width)/MaxWidth

    active_width_constant = width_array.index(get_width_constant(active_width,width_array))

    width_multiplier = width_array[(active_width_constant+1)%len(width_array)]

    return int((MaxWidth-(WinBorder*2))*width_multiplier)

def get_simple_tile(wincount):
    rows = wincount - 1
    layout = []
    if rows == 0:
        layout.append((OrigX,OrigY,MaxWidth,MaxHeight-WinTitle-WinBorder))
        return layout
    else:
        layout.append((OrigX,OrigY,int(MaxWidth*MwFactor),MaxHeight-WinTitle-WinBorder))

    x=OrigX + int((MaxWidth*MwFactor)+(2*WinBorder))
    width=int((MaxWidth*(1-MwFactor))-2*WinBorder)
    height=int(MaxHeight/rows - WinTitle-WinBorder)

    for n in range(0,rows):
        y= OrigY+int((MaxHeight/rows)*(n))
        layout.append((x,y,width,height))

    return layout


def get_vertical_tile(wincount):
    layout = []
    y = OrigY
    width = int(MaxWidth/wincount)
    height = MaxHeight - WinTitle - WinBorder
    for n in range(0,wincount):
        x= OrigX + n * width
        layout.append((x,y,width,height))

    return layout


def get_horiz_tile(wincount):
    layout = []
    x = OrigX
    height = int(MaxHeight/wincount - WinTitle - WinBorder)
    width = MaxWidth
    for n in range(0,wincount):
        y= OrigY + int((MaxHeight/wincount)*(n))
        layout.append((x,y,width,height))

    return layout

def get_max_all(wincount):
    layout = []
    x = OrigX
    y = OrigY
    height = MaxHeight - WinTitle - WinBorder
    width = MaxWidth
    for n in range(0,wincount):
        layout.append((x,y,width,height))

    return layout



def move_active(PosX,PosY,Width,Height):
    windowid = ":ACTIVE:"
    move_window(windowid,PosX,PosY,Width,Height)


def move_window(windowid,PosX,PosY,Width,Height):
    """
    Resizes and moves the given window to the given position and dimensions
    """
    PosX = int(PosX)
    PosY = int(PosY)

    logging.debug("moving window: %s to (%s,%s,%s,%s) " % (windowid,PosX,PosY,Width,Height))

    if windowid == ":ACTIVE:":
		window = "-r "+windowid
    else:
        window = "-i -r "+windowid

	# NOTE: metacity doesn't like resizing and moving in the same step
    # unmaximize
    os.system("wmctrl "+window+" -b remove,maximized_vert,maximized_horz")
    # resize
    command =  "wmctrl " + window +  " -e 0,-1,-1," + str(Width) + "," + str(Height)
    os.system(command)
    # move
    command =  "wmctrl " + window +  " -e 0," + str(max(PosX,0)) + "," + str(max(PosY,0))+ ",-1,-1"
    os.system(command)
    # set properties
    command = "wmctrl " + window + " -b remove,hidden,shaded"
    os.system(command)


def raise_window(windowid):
    if windowid == ":ACTIVE:":
        command = "wmctrl -a :ACTIVE: "
    else:
        command = "wmctrl -i -a " + windowid

    os.system(command)

def get_next_posx(current_x,new_width):

    PosX = 0

    if current_x < MaxWidth/Monitors:
        if new_width < MaxWidth/Monitors - WinBorder:
            PosX=OrigX+new_width
        else:
            PosX=OrigX
    else:
        if new_width < MaxWidth/Monitors - WinBorder:
            PosX=MaxWidth/Monitors+OrigX+new_width
        else:
            PosX=OrigX+MaxWidth/Monitors

    return PosX

def top_option():
    """
    Place the active window along the top of the screen
    """
    active = get_active_window()
    Width=get_middle_Width(active)
    Height=get_top_Height()
    PosX = get_middle_PosX(active,Width)
    PosY=get_top_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def middle_option():
    """
    Place the active window in the middle of the screen
    """
    active = get_active_window()
    Width=get_middle_Width(active)
    Height=get_middle_Height()
    PosX = get_middle_PosX(active,Width)
    PosY= get_middle_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def top_left_option():
    """
    Place the active window in the top left corner of the screen
    """
    active = get_active_window()
    Width=get_corner_Width(active)
    Height=get_top_Height()
    PosX = get_left_PosX(active,Width)
    PosY=get_top_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def top_right_option():
    """
    Place the active window in the top right corner of the screen
    """
    active = get_active_window()
    Width=get_corner_Width(active)
    Height=get_top_Height()
    PosX = get_right_PosX(active,Width)
    PosY=get_top_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def get_top_Height():
    return get_bottom_Height()

def get_middle_Height():
    return MaxHeight - WinTitle - WinBorder

def get_bottom_Height():
    return MaxHeight/2 - WinTitle - WinBorder

def get_bottom_PosY():
    return MaxHeight/2 + OrigY + WinBorder/2 - (BottomPadding)/WinBorder

def get_middle_PosY():
    return get_top_PosY()

def get_top_PosY():
    return OrigY - TopPadding/WinBorder

def get_middle_Width(active):
    return get_next_width(int(get_window_width_height(active)[0]),CENTER_WIDTHS)+WinBorder

def get_corner_Width(active):
    return get_next_width(int(get_window_width_height(active)[0]),CORNER_WIDTHS)

def get_middle_PosX(active, Width):
    return get_next_posx(int(get_window_x_y(active)[0]),(MaxWidth/Monitors-Width)/2) + WinBorder/4

def get_right_PosX(active,Width):
    return get_next_posx(int(get_window_x_y(active)[0]),MaxWidth/Monitors-Width) - (RightPadding+LeftPadding)/WinBorder

def get_left_PosX(active,Width):
    return get_next_posx(int(get_window_x_y(active)[0]),0)

def bottom_option():
    """
    Place the active window along the bottom of the screen
    """
    active = get_active_window()
    Width= get_middle_Width(active)
    Height=get_bottom_Height()
    PosX = get_middle_PosX(active,Width)
    PosY=get_bottom_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def bottom_right_option():
    """
    Place the active window in the bottom right corner of the screen
    """
    active = get_active_window()
    Width=get_corner_Width(active)
    Height=get_bottom_Height()
    PosX = get_right_PosX(active,Width)
    PosY=get_bottom_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def bottom_left_option():
    """
    Place the active window in the bottom left corner of the screen
    """
    active = get_active_window()
    Width=get_corner_Width(active)
    Height=get_bottom_Height()
    PosX = get_left_PosX(active,Width)
    PosY=get_bottom_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def left_option():
    """
    Place the active window in the left corner of the screen
    """
    active = get_active_window()
    Width=get_corner_Width(active)
    Height=get_middle_Height()
    PosX = get_left_PosX(active,Width)
    PosY=get_middle_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)

def right_option():
    """
    Place the active window in the right corner of the screen
    """
    active = get_active_window()
    Width=get_corner_Width(active)
    Height=get_middle_Height()
    PosX = get_right_PosX(active,Width)
    PosY=get_middle_PosY()
    move_window(active,PosX,PosY,Width,Height)
    raise_window(active)


def compare_win_list(newlist,oldlist):
    templist = []
    for window in oldlist:
        if newlist.count(window) != 0:
            templist.append(window)
    for window in newlist:
        if oldlist.count(window) == 0:
            templist.append(window)
    return templist


def create_win_list():
    Windows = WinList[Desktop]

    if OldWinList == {}:
        pass
    else:
        OldWindows = OldWinList[Desktop]
        if Windows == OldWindows:
            pass
        else:
            Windows = compare_win_list(Windows,OldWindows)

    for win in Windows:
        if is_valid_window(win) == False:
            Windows.remove(win)

    return Windows

def arrange(layout,windows):
    for win , lay  in zip(windows,layout):
        move_window(win,lay[0],lay[1],lay[2],lay[3])
    WinList[Desktop]=windows
    store(WinList,TempFile)


def simple_option():
    """
    The basic tiling layout . 1 Main + all other at the side.
    """
    Windows = create_win_list()
    arrange(get_simple_tile(len(Windows)),Windows)

def swap_windows(window1,window2):
    """
    Swap window1 and window2
    """
    window1_area = map(lambda y:int(y),get_window_width_height(window1))
    window1_position = map(lambda y:int(y)-WinBorder/2,get_window_x_y(window1))
    window2_area = map(lambda y:int(y),get_window_width_height(window2))
    window2_position = map(lambda y:int(y)-WinBorder/2,get_window_x_y(window2))

    move_window(window1,window2_position[0],window2_position[1]-WinTitle,window2_area[0],window2_area[1])
    move_window(window2,window1_position[0],window1_position[1]-WinTitle,window1_area[0],window1_area[1])

def get_largest_window():
    """
    Returns the window id of the window with the largest area
    """
    winlist = create_win_list()

    max_area = 0;
    max_win = winlist[0]

    for win in winlist:
        win_area = reduce(lambda x,y:int(x)*int(y),get_window_width_height(win))
        if win_area > max_area:
            max_area = win_area
            max_win = win

    return max_win

def swap_grid_option():
    """
    Swap the active window with the largest window
    """
    active_window = get_active_window()
    largest_window = get_largest_window()

    swap_windows(active_window,largest_window)
    raise_window(active_window)

def swap_option():
    """
    Will swap the active window to master column
    """
    winlist = create_win_list()
    active = get_active_window()
    winlist.remove(active)
    winlist.insert(0,active)
    arrange(get_simple_tile(len(winlist)),winlist)


def vertical_option():
    """
    Simple vertical tiling
    """
    winlist = create_win_list()
    active = get_active_window()
    winlist.remove(active)
    winlist.insert(0,active)
    arrange(get_vertical_tile(len(winlist)),winlist)


def horizontal_option():
    """
    Simple horizontal tiling
    """
    winlist = create_win_list()
    active = get_active_window()
    winlist.remove(active)
    winlist.insert(0,active)
    arrange(get_horiz_tile(len(winlist)),winlist)

def cycle_option():
    """
    Cycle all the windows in the master pane
    """
    winlist = create_win_list()
    winlist.insert(0,winlist[len(winlist)-1])
    winlist = winlist[:-1]
    arrange(get_simple_tile(len(winlist)),winlist)

def maximize_option():
    """
    Maximize the active window
    """
    Width=MaxWidth
    Height=MaxHeight - WinTitle -WinBorder
    PosX=LeftPadding
    PosY=TopPadding
    move_active(PosX,PosY,Width,Height)
    raise_window(":ACTIVE:")

def max_all_option():
    """
    Maximize all windows
    """
    winlist = create_win_list()
    active = get_active_window()
    winlist.remove(active)
    winlist.insert(0,active)
    arrange(get_max_all(len(winlist)),winlist)

def h_flag():
    """
    Display usage information
    """
    help_option()

def help_option():
    """
    Display usage information
    """
    print "\nUsage: %s [FLAG] [OPTION]\n" % os.path.basename(sys.argv[0])

    option_list = []
    flag_list = []

    for key,value in globals().items():
        if type(value) == types.FunctionType:
            if key.endswith("_option"):
                option_list.append((key.rsplit("_",1)[0],value.__doc__))
            elif key.endswith("_flag"):
                flag_list.append((key.rsplit("_",1)[0],value.__doc__))

    option_list.sort()
    flag_list.sort()

    print " Options:"
    for option,description in option_list:
        print " %-16s - %s" % (option,description.replace("\n"," "))

    print ""

    print " Flags:"
    for flag,description in flag_list:
        print " -%-16s - %s" % (flag,description.replace("\n"," "))

    print ""
    version_option()

def eval_function(function_string):
    """
    Evaulate the given function.
    """
    for key,value in globals().items():
        if key == function_string and type(value) == types.FunctionType:
            value()
            return

    log.warn("Unrecognized option: "+function_string.rsplit("_",1)[0])

def initialize_global_variables():
    """
    Initialize the global variables
    """

    # Screen Padding
    global BottomPadding, TopPadding, LeftPadding, RightPadding
    # Window Decoration
    global WinTitle, WinBorder
    # Grid Layout
    global CORNER_WIDTHS, CENTER_WIDTHS, Monitors, WidthAdjustment
    # Simple Layout
    global MwFactor
    # System Desktop and Screen Information
    global MaxWidth, MaxHeight, OrigX, OrigY, Desktop, WinList, OldWinList
    # Miscellaneous
    global TempFile, WindowFilter

    Config = initconfig()
    cfgSection="DEFAULT"

    # use "default" for configurations written using the original stiler
    if Config.has_section("default"):
        cfgSection="default"

    BottomPadding = Config.getint(cfgSection,"BottomPadding")
    TopPadding = Config.getint(cfgSection,"TopPadding")
    LeftPadding = Config.getint(cfgSection,"LeftPadding")
    RightPadding = Config.getint(cfgSection,"RightPadding")
    WinTitle = Config.getint(cfgSection,"WinTitle")
    WinBorder = Config.getint(cfgSection,"WinBorder")
    MwFactor = Config.getfloat(cfgSection,"MwFactor")
    TempFile = Config.get(cfgSection,"TempFile")
    Monitors = Config.getint(cfgSection,"Monitors")
    WidthAdjustment = Config.getfloat(cfgSection,"WidthAdjustment")
    WindowFilter = Config.getboolean(cfgSection,"WindowFilter")
    CORNER_WIDTHS = map(lambda y:float(y),Config.get(cfgSection,"GridWidths").split(","))

    # create the opposite section for each corner_width
    opposite_widths = []
    for width in CORNER_WIDTHS:
        opposite_widths.append(round(abs(1.0-width),2))

    # add the opposites
    CORNER_WIDTHS.extend(opposite_widths)

    CORNER_WIDTHS=list(set(CORNER_WIDTHS)) # filter out any duplicates
    CORNER_WIDTHS.sort()

    CENTER_WIDTHS = filter(lambda y: y < 0.5, CORNER_WIDTHS)
    CENTER_WIDTHS = map(lambda y:round(abs(y*2-1.0),2),CENTER_WIDTHS)
    CENTER_WIDTHS.append(1.0)				 # always allow max for centers
    CENTER_WIDTHS = list(set(CENTER_WIDTHS)) # filter dups
    CENTER_WIDTHS.sort()

    # Handle multiple monitors
    CORNER_WIDTHS=map(lambda y:round(y/Monitors,2)+WidthAdjustment,CORNER_WIDTHS)
    CENTER_WIDTHS=map(lambda y:round(y/Monitors,2)+WidthAdjustment,CENTER_WIDTHS)

    logging.debug("corner widths: %s" % CORNER_WIDTHS)
    logging.debug("center widths: %s" % CENTER_WIDTHS)

    (Desktop,OrigXstr,OrigYstr,MaxWidthStr,MaxHeightStr,WinList) = initialize()
    MaxWidth = int(MaxWidthStr) - LeftPadding - RightPadding
    MaxHeight = int(MaxHeightStr) - TopPadding - BottomPadding
    OrigX = int(OrigXstr) + LeftPadding
    OrigY = int(OrigYstr) + TopPadding
    OldWinList = retrieve(TempFile)


def main():
    """
    Determine what needs to be done.
    """

    # we need options!
    if len(sys.argv) == 1:
        help_option()
        sys.exit(1)

    # check and set any flags passed from the command line
    for arg in sys.argv:
        if arg == sys.argv[0]:
            continue
        elif arg.startswith("-"):
            eval_function(arg.split("-")[1]+"_flag")

    # check to see if the system has all the required programs
    required_programs=["wmctrl","xprop","xwininfo"]
    if has_required_programs(required_programs) == False:
        sys.exit(1)

    initialize_global_variables()

    # parse the args to determine what should be done
    for arg in sys.argv:
        if arg == sys.argv[0]:
            continue
        elif arg.startswith("-"):
            continue
        else:
            eval_function(arg+"_option")

if __name__ == "__main__":
    main()
else:
    log.warn("Importing is not fully tested.  Use at your own risk.")
