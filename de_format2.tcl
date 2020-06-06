# de_format2.tcl :
# che, 2020 year

#=======================================================================

#=======================================================================
proc UIPB__format { src_file dst_file } {
  
    set tm1 [clock seconds]
    set tm2 [clock format $tm1 -format "%M:%S"]
  
    set dc [ open $dst_file "w" ] ;
    set src [ open $src_file "r" ] ;
  
    set s 0
    set k  -1 ;
    while { ![ eof $src ] } {
       incr k;
       gets $src line ;
       if {[ eof $src ]} { break; }
       set l [ string length $line ]
       set r1 [ regexp -all -- {(\{)+} $line ]
        set r2 [ regexp -all -- {(\})+} $line ]
       set r3 [ expr ($r1 - $r2) ]
       if {($r2==1 && $r3==-1)} { 
          	set s [ expr ($s + $r3) ] ; 
            set r3 0 ;
       }
   
       set tr [ string repeat " " $s ]

	   if {[regexp -all -- {(proc )+} $line ]} { 
        	set tr "\n\#[ string repeat "=" 71 ]\n" ; 
        	set s 1 ;
     }
 
     ;# OutPut in File
     puts $dc "$tr$line" ;
 
     set s [ expr ($s + $r3) ]
 
  }

  close $src

  flush $dc
  close $dc

  set tm1 [clock seconds]
  set tm3 [clock format $tm1 -format "%M:%S"]

  puts "\n------\n $src_file -> $dst_file = done " ;
  puts " Start = $tm2 , End = $tm3\n------"

  return 0 ;
}

#=======================================================================

 global env

 set script [info script]
 if {$script != {}} {
    set dir [file dirname $script]
  } else {
    set dir [pwd]
 }

 set ext ".tcl2"
 foreach fn [glob -nocomplain -directory $dir *.tcl] {
     set tclFile [file rootname $fn]$ext
     if {![file exists $tclFile]} {
        puts "UIPB__format $fn -> $tclFile" ;
        UIPB__format $fn $tclFile ;
  		file delete -force -- $fn
      } else {
      	puts " ------ $tclFile - exists" ;
     }
 }
 
 set ext ".tcl"
 foreach fn [glob -nocomplain -directory $dir *.tcl2] {
     set tclFile [file rootname $fn]$ext
     if {![file exists $tclFile]} {
  		file rename -force -- $fn $tclFile
      } else {
      	puts " ------ $tclFile - exists" ;
     }
 }
 
