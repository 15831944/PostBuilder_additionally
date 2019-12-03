# de_crypt_block2.tcl :
# che, 2013 year

#=======================================================================

global rseed ;
set rseed 0 ;

proc UIPB__random { } {
  global rseed
  set rseed [ expr  int($rseed) ] ;
  set rseed [ expr  abs((37 * $rseed + 67) % 27) ] ;
  return $rseed ;
}

## proc for de_crypt
proc UIPB__decrypt { src_file dst_file } {

  set tm1 [clock seconds]
  set tm2 [clock format $tm1 -format "%M:%S"]

  global rseed
  set dc [ open $dst_file "w" ] ;
  set src [ open $src_file "r" ] ;

  set rseedint 0 ; ## number coding
  set s 0

  set k  -1 ;
  while { ![ eof $src ] } {
    incr k;
    gets $src line ;
    if {[ eof $src ]} { break; }
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
      ;#if {$sl>0} { set sl [ expr $sl - 1 ] ; }
      set line2 [ string range $line2 0 $sl ]
      ;# append line2 "\n\0" ;
 
      set r1 [ regexp -all -- {(\{)+} $line2 ]
      set r2 [ regexp -all -- {(\})+} $line2 ]
      set r3 [ expr ($r1 - $r2) ]
      if {($r2==1 && $r3==-1)} { 
      	set s [ expr ($s + $r3) ] ; 
        set r3 0 ;
      }

      set tr [ string repeat " " $s ]
      if {[regexp -all -- {(proc )+} $line2 ]} { 
      	set tr "\n\#[ string repeat "=" 71 ]\n" ; 
      	set s 1 ;
      }

      ;# OutPut in File
      puts $dc "$tr$line2" ;

      set s [ expr ($s + $r3) ]

    } else {
      set cseed "" ;
      set rseed  0 ;
      set sl [ string length $line ] ;
      for { set i 0 } { $i<$sl } { incr i } {
        set c [ string index $line  $i ] ;
        set c [ expr  158 - [ scan $c "%c" ] ];
        append cseed [ format "%c" $c ] ;
      }
      set rseed [ expr ceil($cseed) ] ;
      set rseedint [ expr int($rseed) ] ;
      puts $dc "\#$rseedint"
    }
  }

  close $src

  flush $dc
  close $dc

  set tm1 [clock seconds]
  set tm3 [clock format $tm1 -format "%M:%S"]

  puts "\n------\n First number N=$rseedint \n $src_file -> $dst_file = done " ;
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

 set ext ".tcl"
 foreach fn [glob -nocomplain -directory $dir *.txt] {
    set tclFile [file rootname $fn]$ext
    if {![file exists $tclFile]} {
        puts "UIPB__decrypt $fn -> $tclFile" ;
        UIPB__decrypt $fn $tclFile ;
        ##file delete -force -- $fn
    } else {
    	puts " ------ $tclFile - exists" ;
    }
 }


