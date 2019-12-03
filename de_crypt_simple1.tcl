#===========================================
# de_crypt_simple1.tcl : 
# че, 2004 year
# кодирование-раскодирование.
# простой способ - типа XOR
#===========================================

proc de_crypt { src_file dst_file } {

  if {![file exists $src_file]} { return -1 ; }
  set src [ open $src_file "r" ] ;

  set dc [ open $dst_file "w" ] ;

  while { ![ eof $src ] } {
    gets $src line ;
    set c  '' ;
    set sl [ string length $line ] ;
    set line2 "";
    for { set i 0 } { $i<$sl } { incr i } {
     set j [ expr ($sl - $i - 1) ] ;
     set c [ string index $line  $j ] ;
     set c [ expr  158 - [ scan $c "%c" ] ];
     set c [ format "%c" $c ]
     append line2 $c ;
    }
	set line2 [ string range $line2 0 $sl ]
	puts $dc $line2
  }

  close $src

  flush $dc
  close $dc

  puts "\n $src_file -> $dst_file ........ done\n" ;

  return 0;
}

proc fileDialog { t } {
  set types {
     {"Tcl\Tk Files"  {.tcl .tk} }
     {"Text files"	  {.txt .dat} }
     {"All files"	 *}
  }   
  switch $t {
   1 { set file [ tk_getOpenFile -initialdir "" -title "Выберите файл...."  -filetypes  $types ] ; }
   2 { set file [ tk_getSaveFile -initialdir "" -title "Выберите файл...."  -filetypes  $types ] ; }
  }
  
  if {$file==""} {
    tk_messageBox -message "Вы не выбрали\задали файл."
	exit ;
  }
  
  return $file
}


proc main { } {
	set fileopen [ fileDialog 1 ]
    set filesave [ fileDialog 2 ]	
    de_crypt $fileopen $filesave ;
	return 0;
}

main


