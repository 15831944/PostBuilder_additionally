#!/bin/sh
# the next line restarts using wish \
exec `which wish` "$0" "$@"

# Tk NotePad by Joseph Acosta
# default global values
global .
set fileName " "
set saveTextMsg 0
set winTitle "Tk NotePad"
set version "Version 0.8.0.1"
set wordWrap none
set printCommand lpr
set BGCOLOR "white"
set FGCOLOR "black"
set BASENAME [string range $argv0 [expr [string last "/" $argv0] + 1] end]

set MODIFIED "Modified..."

# main window settings
eval destroy [winfo child .]
wm title . $winTitle
wm iconname . $winTitle
wm geometry . 80x25
wm minsize . 25 1

#create main menu
menu .filemenu -tearoff 0

# start by setting default font sizes
if [ expr [string compare $tcl_platform(platform) "unix"] ==0] {
	set textFont -Adobe-Helvetica-*-R-Normal-*-14-*
	set menuFont -adobe-helvetica-bold-r-normal--12-*-75-75-*-*-*-*
} else {
	set textFont -Adobe-Helvetica-*-R-Normal-*-10-*
	set menuFont [.filemenu cget -font]
}
.filemenu configure -font $menuFont

# create frames for widget layout
# this is for the text widget and the y scroll bar
frame .bottomTopMenu
pack .bottomTopMenu  -side top -expand 1 -fill both
# where the text widget is packed
frame .bottomleftmenu
pack .bottomleftmenu -in .bottomTopMenu  -side left -expand 1 -fill both
# where the y scrollbar is packed
frame .bottomrightmenu
pack  .bottomrightmenu -in .bottomTopMenu  -side right -expand 0 -fill both
# this is for the x scroll bar at the bottom of the window
frame .bottombottommenu
pack .bottombottommenu -side bottom -expand 0 -fill both

#file menu
menu .filemenu.files -tearoff 0 -font $menuFont
.filemenu  add cascade -label "File" -underline 0 -menu .filemenu.files
.filemenu.files add command -label "New" -underline 0 -command "filesetasnew"
.filemenu.files add command -label "Open..." -underline 0 -command "filetoopen" -accelerator Ctrl+o
.filemenu.files add command -label "Save" -underline 0 -command "filetosave" -accelerator Ctrl+s
.filemenu.files add command -label "Save As..." -underline 5 -command "filesaveas"
.filemenu.files add separator
if {"$tcl_platform(platform)" == "unix"} {
	.filemenu.files add command -label "Print Setup..." -underline 8 -command "printseupselection"
	.filemenu.files add command -label "Print" -underline 0 -command "selectprint"
	.filemenu.files add separator
}
.filemenu.files add command -label "Exit" -underline 1 -command "exitapp"

#edit menu
menu .filemenu.edit -tearoff 0 -font $menuFont
.filemenu add cascade -label "Edit" -underline 0 -menu .filemenu.edit
.filemenu.edit add command -label "Undo" -underline 0 -command " undo_menu_proc" -accelerator Ctrl+z
.filemenu.edit add command -label "Redo" -underline 0 -command "redo_menu_proc" -accelerator Ctrl+y
.filemenu.edit add separator
.filemenu.edit add command -label "Cut" -underline 2 -command "cuttext" -accelerator Ctrl+x
.filemenu.edit add command -label "Copy" -underline 0 -command "copytext" -accelerator Ctrl+c
.filemenu.edit add command -label "Paste" -underline 0 -command "pastetext" -accelerator Ctrl+v
.filemenu.edit add command -label "Delete" -underline 2 -command "deletetext" -accelerator Del
.filemenu.edit add separator
.filemenu.edit add command -label "Select All" -underline 7 -command ".textarea tag add sel 1.0 end" -accelerator Ctrl+/
.filemenu.edit add command -label "Time/Date" -underline 5 -command "printtime"
.filemenu.edit add separator
.filemenu.edit add check -label "Word Wrap" -underline 5 -command "wraptext"

#search menu
menu .filemenu.search -tearoff 0 -font $menuFont
.filemenu add cascade -label "Search" -underline 0 -menu .filemenu.search
.filemenu.search add command -label "Find..." -underline 0 -command "findtext find" -accelerator Ctrl+f
.filemenu.search add command -label "Find Next" -underline 1 -command "findnext find" -accelerator F3
.filemenu.search add command -label "Replace..." -underline 0 -command "findtext replace" -accelerator Ctrl+r

# help menu
menu .filemenu.help -tearoff 0 -font $menuFont
.filemenu add cascade -label "Help" -underline 0 -menu .filemenu.help
.filemenu.help add command -label "Help" -underline 0 -command "helpme"
.filemenu.help add command -label "About" -underline 0 -command "aboutme"

# de-crypt menu
menu .filemenu.decrypt -tearoff 1 -font $menuFont
.filemenu add cascade -label "De-Crypt" -underline 0 -menu .filemenu.decrypt
.filemenu.decrypt add command -label "DeCrypt" -underline 0 -command "decrypt"
.filemenu.decrypt add command -label "Crypt" -underline 0 -command "crypt"

# now make the menu visible
. configure -menu .filemenu

#create text area
text .textarea -relief sunken -bd 2 -xscrollcommand ".xscroll set" \
	-yscrollcommand ".yscroll set" -wrap $wordWrap -width 1 -height 1 \
        -fg $FGCOLOR -bg $BGCOLOR -font $textFont -setgrid 1
scrollbar .yscroll -command ".textarea yview"
scrollbar .xscroll -command ".textarea xview" -orient horizontal
pack .textarea  -in  .bottomleftmenu -side left -expand 1 -fill both
pack .yscroll -in .bottomrightmenu -side right -expand 1 -fill both
pack .xscroll -in .bottombottommenu -expand 1 -fill x
focus .textarea

# this proc just sets the title to what it is passed
proc settitle {WinTitleName} {
	global winTitle fileName
	wm title . "$winTitle - $WinTitleName"
	set fileName $WinTitleName
}

# proc to open files or read a pipe
proc openoninit {thefile} {
    if [string match " " $thefile] {
        fconfigure stdin -blocking 0
        set incoming [read stdin 1]
        if [expr [string length $incoming] == 0] {
            fconfigure stdin -blocking 1
        } else {
            fconfigure stdin -blocking 1
            .textarea insert end $incoming
            while {![eof stdin]} {
                .textarea insert end [read -nonewline stdin]
            }
        }
    } else {
        if [ file exists $thefile ] {
            set newnamefile [open $thefile r]
        } else {
            set newnamefile [open $thefile a+]
        }
        while {![eof $newnamefile]} {
	       .textarea insert end [read -nonewline $newnamefile ]
        }
        close $newnamefile
        settitle $thefile
    }
}

# parse command line arguments
if ($argc>0) {
    for {set i 0} {$i <= $argc } {incr i} {
        if [ file exists [lindex $argv $i] ] {
	    set nameFileToOpen [lindex $argv $i]
	    openoninit $nameFileToOpen
        } else {
              set initvar  [lindex $argv $i]
              case $initvar {
                   -fg {
                         set FGCOLOR [lindex $argv [expr $i+1]]
	         .textarea configure -fg $FGCOLOR
                         incr i }
                   -bg {
                         set BGCOLOR [lindex $argv [expr $i+1]]
	         .textarea configure -bg $BGCOLOR
                         incr i }
                   -p {
                        set nameFileToOpen " "
	        openoninit $nameFileToOpen }
                   -f {
                        set nameFileToOpen [lindex $argv [expr $i+1]]
	        eval exec $BASENAME $nameFileToOpen -fg $FGCOLOR -bg $BGCOLOR &
                        incr i }
                   -nf {
                        set nameFileToOpen [lindex $argv [expr $i+1]]
	        openoninit $nameFileToOpen
                        incr i }
              }
        }
    }
}

# because of a change in tcl / tk I now have to guess
# how to set the cursor position
proc textSetCursor {pos} {
        if { [ catch { tkTextSetCursor .textarea $pos } ] } {
                catch { tk::TextSetCursor .textarea $pos } ]
        }
}

# help menu
proc helpme {} {
	tk_messageBox -title "Basic Help" -type ok -message "This is a simple ASCII editor like many others. \
Please see the README.help and other documentation files for help."
}

# about menu
proc aboutme {} {
        global winTitle version
	tk_messageBox -title "About" -type ok -message "$winTitle $version\n by Joseph Acosta.\n\
		joeja@mindspring.com"
}


global next
set next 1 ;

proc rand1 { } {
 global next
 set next [ expr $next*1103515245+12345 ] ;
 set t [ expr int(($next/65536)%32768) ] ;
 return $t ;
}

proc srand1 { seed } {
 global next
 set next $seed;
}

global rseed ;
set rseed 0 ;

proc UIPB__random { } {
  global rseed
  set rseed [ expr  int($rseed) ] ;
  set rseed [ expr  abs((37 * $rseed + 67) % 27) ] ;
  return $rseed ;
}

# decrypt menu
proc decrypt {} {
  global rseed

  set src1 [.textarea get 0.0 end ]
  set src [ split $src1 "\n" ]
  set dst [ list ]
  set ss [ llength $src ] ;

  set k  -1 ;
  while { $ss!=0 } {
    incr k;
    set line [ lindex $src $k ] ;
	set l [ string length $line ]
    set c  '' ;
    if {$k} {
      set v4 [ UIPB__random ];
	  set line1 [ string range $line $v4 end ]
	  set s1 [ string length $line1 ] ;
	  set s2 [ UIPB__random ] ;
      set sl [ expr ( $s1 - $s2 ) ];
      set line2 "";
      for { set i 0 } { $i<$sl } { incr i } {
        set j [ expr ($sl - $i - 1) ] ;
	    set c [ string index $line1  $j ] ;
        set c [ expr  158 - [ scan $c "%c" ] ];
	    set c [ format "%c" $c ]
        append line2 $c ;
      }
	  set line2 [ string range $line2 0 $sl ]
	  set dst [linsert $dst end $line2]
    } else {
      set cseed "" ;
      set rseed  0 ;
      set sl [ string length $line ] ;
      for { set i 0 } { $i<$sl } { incr i } {
        set c [ string index $line  $i ] ;
        set c [ expr  158 - [ scan $c "%c" ] ];
		append cseed [ format "%c" $c ] ;
      }
	  set err "" ;
	  ;#catch {
	    set rseed [ expr ceil($cseed) ]
	  ;#} err;
	  if {$err!=""} {
	    ;#set rseed 0 ;
	    ;#tk_messageBox -title "DeCrypt" -type ok -message "Error!!\n Not set N\n$err"
		;#return ;
	  }
	  set line2 [ expr int($rseed) ] ;
	  set dst [linsert $dst end $line2 ]
    }
	set ss [ expr $ss-1 ]
  }

  .textarea delete 0.0 end
  foreach x $dst {
   .textarea insert end  "$x\n"
  }

}

# crypt menu
proc crypt {} {

  global base ;
  set base .base
  catch {destroy $base}
  toplevel $base
	wm title $base "Setup N(0)"
	setwingeom $base
	label $base.label#1 \
		-justify right \
		-text N(0)=
	catch {
		$base.label#1 configure \
			-font {-*-MS Sans Serif-Medium-R-Normal-*-*-120-*-*-*-*-*-*}
	}

	entry $base.entry1 \
		-borderwidth 1 \
		-takefocus 1 \
		-textvariable entry
	catch {
		$base.entry1 configure \
			-font {-*-MS Sans Serif-Medium-R-Normal-*-*-120-*-*-*-*-*-*}
	}

	button $base.button#1 \
		-command { comRseed $base } \
		-text Apply
	catch {
		$base.button#1 configure \
			-font {-*-MS Sans Serif-Medium-R-Normal-*-*-120-*-*-*-*-*-*}
	}


	# Geometry management

	grid $base.label#1 -row 1 -column 1  \
		-sticky ew
	grid $base.entry1 -row 1 -column 2  \
		-sticky ew
	grid $base.button#1 -row 2 -column 2  \
		-sticky nesw

# additional interface code
	bind $base <Control-c> "destroy $base"
	focus $base.entry1
	grab $base

	global entry
	set entry 0

proc comRseed { w } {
 global entry
 global rseed
 set err ""
 ;#catch {
  set rseed [ expr ceil($entry) ] ;
 ;# } err;
 ;#if {$err!=""} { set rseed 0 ; }
 if {$rseed<=0} { set rseed 0 ; }
 set entry $rseed
 destroy $w
 crypt_ex
}

# end additional interface code
}


# crypt menu
proc crypt_ex { } {
  set src1 [.textarea get 0.0 end ]
  set src [ split $src1 "\n" ]
  set dst [ list ]
  set ss [ llength $src ] ;

  global rseed
  #set rseed 15 ;
  set rseed [ expr int($rseed) ] ;

  set line "$rseed" ;
  set cseed  "" ;
  set sl [ string length $line ] ;
  for { set i 0 } { $i<$sl } { incr i } {
    set c [ string index $line  $i ] ;
    set c [ expr  158 - [ scan $c "%c" ] ];
	append cseed [ format "%c" $c ] ;
  }
  set dst [linsert $dst end "$cseed" ]

  set k  -1 ;
  while { $ss!=0 } {
    incr k
    set line [ lindex $src $k ] ;
    set l [ string length $line ]
    set c  '' ;

	  set sl $l
	  set line1 $line

    set line2 "";
    for { set i 0 } { $i<$sl } { incr i } {
     set j [ expr ($sl - $i - 1) ] ;
     set c [ string index $line1  $j ] ;
     set c [ expr  158 - [ scan $c "%c" ] ];
     set c [ format "%c" $c ]
     append line2 $c ;
    }
	set line2 [ string range $line2 0 $sl ]

	;# Generator psevdo- number
	set t [ pid ]
	srand1 $t

	set f1 [ UIPB__random ];
	set str1 ""
	for { set i 0 } { $i<$f1 } { incr i } {
	  set rnd [ rand1 ]
		set rnd [ expr $rnd%255 ]
    set c [ format "%c" $rnd ]
		append str1 $c ;
	}
	set f2 [ UIPB__random ];
	set str2 ""
	for { set i 0 } { $i<$f2 } { incr i } {
	  set rnd [ rand1 ]
		set rnd [ expr $rnd%255 ]
    set c [ format "%c" $rnd ]
		append str2 $c ;
	}
	set dst [linsert $dst end "${str1}${line2}${str2}" ]

	set ss [ expr $ss-1 ]
  }

  .textarea delete 0.0 end
  foreach x $dst {
   .textarea insert end  "$x\n"
  }

  return 0;
}

# generic case switcher for message box
proc switchcase {yesfn nofn} {
    global saveTextMsg
    if [ expr [string compare $saveTextMsg 1] ==0 ] {
	set answer [tk_messageBox -message "The contents of this file may have changed, do you wish to to save your changes?" \
	-title "New Confirm?" -type yesnocancel -icon question]
	case $answer {
	     yes { if {[eval $yesfn] == 1} { $nofn } }
             no {$nofn }
	}
    } else {
   	$nofn
    }
}

# new file
proc filesetasnew {} {
	switchcase filetosave setTextTitleAsNew
}

proc setTextTitleAsNew {} {
	.textarea delete 0.0 end
	global winTitle fileName
	set fileName " "
	wm title . $winTitle
	outccount
}

# kill main window
proc killwin {} {
	destroy .
}

# exit app
proc exitapp {} {
	switchcase filetosave killwin
}

# bring up open win
proc showopenwin {} {
	set types {
	{"All files"		*}
	}
	set file [tk_getOpenFile -filetypes $types -parent .]
	if [string compare $file ""] {
		setTextTitleAsNew
		openoninit $file
		outccount
	}
}

#open an existing file
proc filetoopen {} {
  	switchcase filetosave showopenwin
}

# generic save function
proc writesave {nametosave} {
    set FileNameToSave [open $nametosave w+]
    puts -nonewline $FileNameToSave [.textarea get 0.0 end]
    close $FileNameToSave
    outccount
}

#save a file
proc filetosave {} {
    global fileName
    #check if file exists file
    if [file exists $fileName] {
	writesave $fileName
        return 1
    } else {
	 return [eval filesaveas]
    }
}

#save a file as
proc filesaveas {} {
    set types {
	{"All files"		*}
    }
    set myfile [tk_getSaveFile -filetypes $types -parent . -initialfile Untitled]
    if { [expr [string compare $myfile ""]] != 0} {
	writesave  $myfile
	settitle $myfile
        return 1
    }
    return 0
}

# proc to set child window position
proc setwingeom {wintoset} {
    wm resizable $wintoset 0 0
    set myx [expr (([winfo screenwidth .]/2) - ([winfo reqwidth $wintoset]))]
    set myy [expr (([winfo screenheight .]/2) - ([winfo reqheight $wintoset]/2))]
    wm geometry $wintoset +$myx+$myy
    set topwin [ winfo parent $wintoset ]
    if { [ winfo viewable [ winfo toplevel $topwin ] ] } {
        wm transient $wintoset $topwin
    }
}

# procedure to setup the printer
proc printseupselection {} {
	global printCommand
	set print .print
	catch {destroy $print}
	toplevel $print
	wm title $print "Print Setup"
	setwingeom $print
	frame $print.top
	frame $print.bottom
	label $print.top.label -text "Print Command: "
	entry $print.top.print -textvariable printsetupnew -width 40
	$print.top.print delete 0 end
	set printvar $printCommand
	$print.top.print insert 0 $printvar
	button $print.bottom.ok -text "OK" -command "addtoprint $print"
	button $print.bottom.cancel -text "Cancel" -command "destroy $print"

	pack $print.top -side top -expand 0
	pack $print.bottom -side bottom -expand 0
	pack $print.top.label $print.top.print -in $print.top -side left -fill x -fill y
	pack $print.bottom.ok $print.bottom.cancel -in $print.bottom -side left -fill x -fill y
	bind $print <Return> "addtoprint $print"
	bind $print <Escape> "destroy $print"

    proc addtoprint {prnt} {
         global printCommand
         set printCommand [$prnt.top.print get]
         destroy $prnt
    }
}

# procedure to print
proc selectprint {} {
    set TempPrintFile [open /tmp/tkpadtmpfile w]
    puts -nonewline $TempPrintFile [.textarea get 0.0 end]
    close $TempPrintFile
    global printCommand
    set prncmd $printCommand
    eval exec $prncmd /tmp/tkpadtmpfile
    eval exec rm -f /tmp/tkpadtmpfile
}

#cut text procedure
proc deletetext {} {
    set cuttexts [selection own]
    if {$cuttexts != "" } {
        $cuttexts delete sel.first sel.last
        selection clear
    }
    inccount
}

#cut text procedure
proc cuttext {} {
    tk_textCut .textarea
    inccount
}

#copy text procedure
proc copytext {} {
    tk_textCopy .textarea
    inccount
}

#paste text procedure
proc pastetext {} {
    global tcl_platform
    if {"$tcl_platform(platform)" == "unix"} {
	    catch {
		.textarea delete sel.first sel.last
	    }
    }
    tk_textPaste .textarea
    inccount
}

proc FindIt {w} {
	global SearchString SearchPos SearchDir findcase tk_version
	.textarea tag configure sel -background green
	if {$SearchString!=""} {
		if {$findcase=="1"} {
 			set caset "-exact"
		} else {
			set caset "-nocase"
		}
		if {$SearchDir == "forwards"} {
			set limit end
		} else {
			set limit 1.0
		}
		set SearchPos [ .textarea search -count len $caset -$SearchDir $SearchString $SearchPos $limit]
		set len [string length $SearchString]
		if {$SearchPos != ""} {
        			.textarea see $SearchPos
				textSetCursor $SearchPos
			.textarea tag add sel $SearchPos  "$SearchPos + $len char"

			if {$SearchDir == "forwards"} {
        				set SearchPos "$SearchPos + $len char"
			}
            		} else {
	           		set SearchPos "0.0"
	          	}
 	}
	focus .textarea
}

proc ReplaceIt {} {
	global SearchString SearchDir ReplaceString SearchPos findcase
	if {$SearchString != ""} {
	    if {$findcase=="1"} {
		set caset "-exact"
	    } else {
		set caset "-nocase"
	    }
	    if {$SearchDir == "forwards"} {
		set limit end
	    } else {
		set limit 1.0
	    }
	    set SearchPos [ .textarea search -count len $caset -$SearchDir $SearchString $SearchPos $limit]
		set len [string length $SearchString]
	    if {$SearchPos != ""} {
        		.textarea see $SearchPos
               		.textarea delete $SearchPos "$SearchPos+$len char"
        		.textarea insert $SearchPos $ReplaceString
		if {$SearchDir == "forwards"} {
        			set SearchPos "$SearchPos+$len char"
		}
	    } else {
	       	set SearchPos "0.0"
	    }
	}
	inccount
}

proc ReplaceAll {} {
      global SearchPos SearchString
       if {$SearchString != ""} {
                ReplaceIt
	while {$SearchPos!="0.0"} {
		ReplaceIt
	}
       }
}

proc CancelFind {w} {
    .textarea tag delete tg1
    destroy $w
}

proc ResetFind {} {
    global SearchPos
    set SearchPos insert
}

# procedure to find text
proc findtext {typ} {
	global SearchString SearchDir ReplaceString findcase c find
	set find .find
	catch {destroy $find}
	toplevel $find
	wm title $find "Find"
	setwingeom $find
	ResetFind
	frame $find.l
	frame $find.l.f1
	label $find.l.f1.label -text "Find what:" -width 11
	entry $find.l.f1.entry  -textvariable SearchString -width 30
	pack $find.l.f1.label $find.l.f1.entry -side left
	$find.l.f1.entry selection range 0 end
	if {$typ=="replace"} {
		frame $find.l.f2
		label $find.l.f2.label2 -text "Replace with:" -width 11
		entry $find.l.f2.entry2  -textvariable ReplaceString -width 30
		pack $find.l.f2.label2 $find.l.f2.entry2 -side left
		pack $find.l.f1 $find.l.f2 -side top
	} else {
		pack $find.l.f1
	}
	frame $find.f2
	button $find.f2.button1 -text "Find Next" -command "FindIt $find" -width 10 -height 1 -underline 5
	button $find.f2.button2 -text "Cancel" -command "CancelFind $find" -width 10 -underline 0
	if {$typ=="replace"} {
		button $find.f2.button3 -text "Replace" -command ReplaceIt -width 10 -height 1 -underline 0
		button $find.f2.button4 -text "Replace All" -command ReplaceAll -width 10 -height 1 -underline 8
		pack $find.f2.button3 $find.f2.button4 $find.f2.button2  -pady 4
	} else {
		pack $find.f2.button1 $find.f2.button2  -pady 4
	}
	frame $find.l.f4
	frame $find.l.f4.f3 -borderwidth 2 -relief groove
	radiobutton $find.l.f4.f3.up -text "Up" -underline 0 -variable SearchDir -value "backwards"
	radiobutton $find.l.f4.f3.down -text "Down"  -underline 0 -variable SearchDir -value "forwards"
	$find.l.f4.f3.down invoke
	pack $find.l.f4.f3.up $find.l.f4.f3.down -side left
	checkbutton $find.l.f4.cbox1 -text "Match case" -variable findcase -underline 0
	pack $find.l.f4.cbox1 $find.l.f4.f3 -side left -padx 10
	pack $find.l.f4 -pady 11
	pack $find.l $find.f2 -side left -padx 1
	bind $find <Escape> "destroy $find"

     # each widget must be bound to th eevents of the other widgets
     proc bindevnt {widgetnm types find} {
	if {$types=="replace"} {
		bind $widgetnm <Return> "ReplaceIt"
		bind $widgetnm <Control-r> "ReplaceIt"
		bind $widgetnm <Control-a> "ReplaceAll"
	} else {
		bind $widgetnm <Return> "FindIt $find"
		bind $widgetnm <Control-n> "FindIt $find"
	}
	bind $widgetnm <Control-m> { $find.l.f4.cbox1 invoke }
	bind $widgetnm <Control-u> { $find.l.f4.f3.up invoke }
	bind $widgetnm <Control-d> { $find.l.f4.f3.down invoke }
     }
	if {$typ == "replace"} {
   		bindevnt $find.f2.button3 $typ $find
		bindevnt $find.f2.button4 $typ $find
	} else {
		bindevnt $find.f2.button1 $typ $find
  	        bindevnt $find.f2.button2 $typ $find
	}
        bindevnt $find.l.f4.f3.up  $typ $find
        bindevnt $find.l.f4.f3.down $typ $find
        bindevnt $find.l.f4.cbox1 $typ $find
	bindevnt $find.l.f1.entry $typ $find
	bind $find <Control-c> "destroy $find"
	focus $find.l.f1.entry
	grab $find
}

# proc for find next
proc findnext {typof} {
	global SearchString SearchDir ReplaceString findcase c find
	if [catch {expr [string compare $SearchString "" ] }] {
		findtext $typof
	} else {
	 	FindIt $find
	}
}

#procedure to set the time change %R to %I:%M for 12 hour time display
proc printtime {} {
.textarea insert insert [clock format [clock seconds] -format "%R %p %D"]
inccount
}

# binding for wordwrap
proc wraptext {} {
    global wordWrap
    if [expr [string compare $wordWrap word] == 0] {
	set wordWrap none
    } else {
	set wordWrap word
    }
    .textarea configure -wrap $wordWrap
}

## NOTE modifiedstatus is declared in the linenum.pth
## so if it it not included we dont want to throw the error
## we just want to ignore, thus the catch...
# this sets saveTextMsg to 1 for message boxes
proc inccount {} {
    global saveTextMsg MODIFIED
    set saveTextMsg 1
    catch {modifiedstatus $MODIFIED}
}
# this resets saveTextMsg to 0
proc outccount {} {
    global saveTextMsg
    set saveTextMsg 0
    catch {modifiedstatus " "}
}

# catch the kill of the windowmanager
wm protocol . WM_DELETE_WINDOW exitapp

#bindings
bind All <Alt-F> {}
bind All <Alt-E> {}
bind All <Alt-S> {}
bind ALL <Alt-H> {}
bind . <F3> {findnext find}
bind . <Control-x> {cuttext}
bind . <Control-c> {copytext}
bind . <Control-s> {filetosave}
bind Text <Control-o> {}
bind Text <Control-f> {}
bind . <Control-o> {filetoopen}
bind . <Control-z> {undo_menu_proc}
bind . <Control-y> {redo_menu_proc}
bind . <Control-f> {findtext find}
bind . <Control-r> {findtext replace}

# because windows is 'different' and mac is unknown
if [ expr [string compare $tcl_platform(platform) "unix"] ==0] {
	#events
	set tk_strictMotif 0
	event delete <<Cut>> <Control-x>
	event delete <<Paste>> <Control-v>
        event delete <<Paste>> <Control-Key-y>
	# more bindings
	bind Text <Control-v> {}
	bind .textarea <Control-v> {pastetext}
}

textSetCursor "1.0"
###################################################################
#set zed_dir [file dirname [info script]]
# here is where the undo stuff begins
if {![info exists classNewId]} {
    # work around object creation between multiple include of this file problem
    set classNewId 0
}

proc new {className args} {
    # calls the constructor for the class with optional arguments
    # and returns a unique object identifier independent of the class name

    global classNewId
    # use local variable for id for new can be called recursively
    set id [incr classNewId]
    if {[llength [info procs ${className}:$className]]>0} {
        # avoid catch to track errors
        eval ${className}:$className $id $args
    }
    return $id
}

proc delete {className id} {
    # calls the destructor for the class and delete all the object data members

    if {[llength [info procs ${className}:~$className]]>0} {
        # avoid catch to track errors
        ${className}:~$className $id
    }
    global $className
    # and delete all this object array members if any (assume that they were stored as $className($id,memberName))
    foreach name [array names $className "$id,*"] {
        unset ${className}($name)
    }
}

proc lifo:lifo {id {size 2147483647}} {
    global lifo
    set lifo($id,maximumSize) $size
    lifo:empty $id
}

proc lifo:push {id data} {
    global lifo
    inccount
    lifo:tidyUp $id
    if {$lifo($id,size)>=$lifo($id,maximumSize)} {
        unset lifo($id,data,$lifo($id,first))
        incr lifo($id,first)
        incr lifo($id,size) -1
    }
    set lifo($id,data,[incr lifo($id,last)]) $data
    incr lifo($id,size)
}

proc lifo:pop {id} {
    global lifo
    inccount
    lifo:tidyUp $id
    if {$lifo($id,last)<$lifo($id,first)} {
        error "lifo($id) pop error, empty"
    }
    # delay unsetting popped data to improve performance by avoiding a data copy
    set lifo($id,unset) $lifo($id,last)
    incr lifo($id,last) -1
    incr lifo($id,size) -1
    return $lifo($id,data,$lifo($id,unset))
}

proc lifo:tidyUp {id} {
    global lifo
    if {[info exists lifo($id,unset)]} {
        unset lifo($id,data,$lifo($id,unset))
        unset lifo($id,unset)
    }
}

proc lifo:empty {id} {
    global lifo
    lifo:tidyUp $id
    foreach name [array names lifo $id,data,*] {
        unset lifo($name)
    }
    set lifo($id,size) 0
    set lifo($id,first) 0
    set lifo($id,last) -1
}

proc textUndoer:textUndoer {id widget {depth 2147483647}} {
    global textUndoer

    if {[string compare [winfo class $widget] Text]!=0} {
        error "textUndoer error: widget $widget is not a text widget"
    }
    set textUndoer($id,widget) $widget
    set textUndoer($id,originalBindingTags) [bindtags $widget]
    bindtags $widget [concat $textUndoer($id,originalBindingTags) UndoBindings($id)]

    bind UndoBindings($id) <Control-u> "textUndoer:undo $id"

    # self destruct automatically when text widget is gone
    bind UndoBindings($id) <Destroy> "delete textUndoer $id"

    # rename widget command
    rename $widget [set textUndoer($id,originalCommand) textUndoer:original$widget]
    # and intercept modifying instructions before calling original command
    proc $widget {args} "textUndoer:checkpoint $id \$args;
		global search_count;
		eval $textUndoer($id,originalCommand) \$args"

    set textUndoer($id,commandStack) [new lifo $depth]
    set textUndoer($id,cursorStack) [new lifo $depth]
    #lee
    textRedoer:textRedoer $id $widget $depth
}

proc textUndoer:~textUndoer {id} {
    global textUndoer

    bindtags $textUndoer($id,widget) $textUndoer($id,originalBindingTags)
    rename $textUndoer($id,widget) ""
    rename $textUndoer($id,originalCommand) $textUndoer($id,widget)
    delete lifo $textUndoer($id,commandStack)
    delete lifo $textUndoer($id,cursorStack)
    #lee
    textRedoer:~textRedoer $id
}

proc textUndoer:checkpoint {id arguments} {
    global textUndoer textRedoer

    # do nothing if non modifying command
    if {[string compare [lindex $arguments 0] insert]==0} {
        textUndoer:processInsertion $id [lrange $arguments 1 end]
        if {$textRedoer($id,redo) == 0} {
           textRedoer:reset $id
        }
    }
    if {[string compare [lindex $arguments 0] delete]==0} {
        textUndoer:processDeletion $id [lrange $arguments 1 end]
        if {$textRedoer($id,redo) == 0} {
           textRedoer:reset $id
        }
    }
}

proc textUndoer:processInsertion {id arguments} {
    global textUndoer

    set number [llength $arguments]
    set length 0
    # calculate total insertion length while skipping tags in arguments
    for {set index 1} {$index<$number} {incr index 2} {
        incr length [string length [lindex $arguments $index]]
    }
    if {$length>0} {
        set index [$textUndoer($id,originalCommand) index [lindex $arguments 0]]
        lifo:push $textUndoer($id,commandStack) "delete $index $index+${length}c"
        lifo:push $textUndoer($id,cursorStack) [$textUndoer($id,originalCommand) index insert]
    }
}

proc textUndoer:processDeletion {id arguments} {
    global textUndoer

    set command $textUndoer($id,originalCommand)
    lifo:push $textUndoer($id,cursorStack) [$command index insert]

    set start [$command index [lindex $arguments 0]]
    if {[llength $arguments]>1} {
        lifo:push $textUndoer($id,commandStack) "insert $start [list [$command get $start [lindex $arguments 1]]]"
    } else {
        lifo:push $textUndoer($id,commandStack) "insert $start [list [$command get $start]]"
    }
}

proc textUndoer:undo {id} {
    global textUndoer

    if {[catch {set cursor [lifo:pop $textUndoer($id,cursorStack)]}]} {
        return
    }

    set popArgs [lifo:pop $textUndoer($id,commandStack)]
    textRedoer:checkpoint $id $popArgs

    eval $textUndoer($id,originalCommand) $popArgs
    # now restore cursor position
    $textUndoer($id,originalCommand) mark set insert $cursor
    # make sure insertion point can be seen
    $textUndoer($id,originalCommand) see insert
}


proc textUndoer:reset {id} {
    global textUndoer
    lifo:empty $textUndoer($id,commandStack)
    lifo:empty $textUndoer($id,cursorStack)
}

#########################################################################
proc textRedoer:textRedoer {id widget {depth 2147483647}} {
    global textRedoer
    if {[string compare [winfo class $widget] Text]!=0} {
        error "textRedoer error: widget $widget is not a text widget"
    }
    set textRedoer($id,commandStack) [new lifo $depth]
    set textRedoer($id,cursorStack) [new lifo $depth]
    set textRedoer($id,redo) 0
}

proc textRedoer:~textRedoer {id} {
    global textRedoer
    delete lifo $textRedoer($id,commandStack)
    delete lifo $textRedoer($id,cursorStack)
}


proc textRedoer:checkpoint {id arguments} {
    global textUndoer textRedoer
    # do nothing if non modifying command
    if {[string compare [lindex $arguments 0] insert]==0} {
        textRedoer:processInsertion $id [lrange $arguments 1 end]
    }
    if {[string compare [lindex $arguments 0] delete]==0} {
        textRedoer:processDeletion $id [lrange $arguments 1 end]
    }
}

proc textRedoer:processInsertion {id arguments} {
    global textUndoer textRedoer
    set number [llength $arguments]
    set length 0
    # calculate total insertion length while skipping tags in arguments
    for {set index 1} {$index<$number} {incr index 2} {
        incr length [string length [lindex $arguments $index]]
    }
    if {$length>0} {
        set index [$textUndoer($id,originalCommand) index [lindex $arguments 0]]
        lifo:push $textRedoer($id,commandStack) "delete $index $index+${length}c"
        lifo:push $textRedoer($id,cursorStack) [$textUndoer($id,originalCommand) index insert]
    }
}

proc textRedoer:processDeletion {id arguments} {
    global textUndoer textRedoer
    set command $textUndoer($id,originalCommand)
    lifo:push $textRedoer($id,cursorStack) [$command index insert]

    set start [$command index [lindex $arguments 0]]
    if {[llength $arguments]>1} {
        lifo:push $textRedoer($id,commandStack) "insert $start [list [$command get $start [lindex $arguments 1]]]"
    } else {
        lifo:push $textRedoer($id,commandStack) "insert $start [list [$command get $start]]"
    }
}
proc textRedoer:redo {id} {
    global textUndoer textRedoer
    if {[catch {set cursor [lifo:pop $textRedoer($id,cursorStack)]}]} {
        return
    }
    set textRedoer($id,redo) 1
    set popArgs [lifo:pop $textRedoer($id,commandStack)]
    textUndoer:checkpoint $id $popArgs
    eval $textUndoer($id,originalCommand) $popArgs
    set textRedoer($id,redo) 0
    # now restore cursor position
    $textUndoer($id,originalCommand) mark set insert $cursor
    # make sure insertion point can be seen
    $textUndoer($id,originalCommand) see insert
}


proc textRedoer:reset {id} {
    global textRedoer
    lifo:empty $textRedoer($id,commandStack)
    lifo:empty $textRedoer($id,cursorStack)
}

# end of where youd source in undo.tcl

set undo_id [new textUndoer .textarea]
proc undo_menu_proc {} {
	global undo_id
	textUndoer:undo $undo_id
	inccount
}

proc redo_menu_proc {} {
	global undo_id
	textRedoer:redo $undo_id
	inccount
}


