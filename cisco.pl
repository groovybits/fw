# Cisco to Linux conversions

sub citoli () {
  $line = $_[0];

  $oline = $line;
  $line =~ s/permit/ACCEPT/g;
  $line =~ s/deny/DROP/g;
  $line =~ s/reject/REJECT/g;

  $line =~ s/\s+$//g;
  while ($line =~ /  /){$line =~ s/  / /};
  while ($line =~ / any / || $line=~ /any$/ ) {
    $line =~ s/ any / 0\.0\.0\.0 255\.255\.255\.255 /;
    $line =~ s/ any$/ 0\.0\.0\.0 255\.255\.255\.255/;
  } 

  $i=0;
  @linearray = split( / /, $line );
  unshift @linearray, "$int";
  unshift @linearray, "access-list";
  $rule=''; $proto=''; $saddr=''; $sport='';
  $daddr=''; $dport=''; $extra=''; $arg0='';

  foreach $part (@linearray) {
    if ($part =~ /^$/ || $part =~ /^\!/) {
      ;;
    } elsif($i == 1) { ## Interface and direction
      $linearray =~ s/$part //g;
      #($int, $table) = split( /_/, $part );
    } elsif($i == 2) { ## Rule permit,deny,reject
      $linearray =~ s/$part //g;
      $rule = $part;
    } elsif($i == 3) { ## Protocol
      $linearray =~ s/$part //g;
      $proto = $part;
    } elsif($i == 4) { ## SourceAddr
        if($part =~ /^host$/) {
        $saddr = "$linearray[5]/32";
      } else {
        $partip = $part;
        $imask = $linearray[5];

        # Convert mask to CIDR
        &cidr($imask);

        $saddr = "$partip/$bc";
      }
    } elsif($i >= 6 && $part !~ /^[1..65535]$/) {
      ## SourcePort DestAddr DestPort
      if($part =~ /^range$/ && $sport eq '' && $i == 6) {
        $sport = "$linearray[7]:$linearray[8]";
      } elsif($part =~ /^range$/ && $dport eq '') {
        $dport = "$linearray[$i+1]:$linearray[$i+2]";

      } elsif($part =~ /^eq$/ && $sport eq '' && $i == 6) {
        $sport = "$linearray[7]";
      } elsif($part =~ /^eq$/ && $dport eq '') {
              $dport = "$linearray[$i+1]";

      } elsif($part =~ /^gt$/ && $sport eq '' && $i == 6) {
        $sport = ($linearray[7]+1) . ":";
      } elsif($part =~ /^gt$/ && $dport eq '') {
        $dport = ($linearray[$i+1]+1) . ":";

      } elsif($part =~ /^lt$/ && $sport eq '' && $i == 6) {
        $sport = ":" . ($linearray[7]-1);
      } elsif($part =~ /^lt$/ && $dport eq '') {
        $dport = ":" . ($linearray[$i+1]-1);

      } elsif(($part =~ /^log$/ ||
              $part =~ /^nat$/ ||
              $part =~ /^snat$/ ||
              $part =~ /^portfw$/ ||
              $part =~ /^proute$/ ||
              $part =~ /^redir$/ ||
              $part =~ /^shape$/ ||
              $part =~ /^established$/) &&
              $i > 6)
     {
        $extra = $part;
        $arg0 = $linearray[$i+1];

      } elsif($part =~ /^host$/ && $daddr eq '') {
        $daddr = "$linearray[$i+1]/32";

      } elsif ($daddr eq '' &&
               $part =~ /^\d+\.\d+\.\d+\.\d+$/ &&
               $part !~ /^255\./)
      {
        $imask = $linearray[$i+1];
       
        # Convert mask to CIDR
        &cidr($imask);

        $daddr = "$part/$bc";
      }
    }
    $i++;
  }
  # End of Cisco To Linux Conversion.
}

## Get CIDR Bit Mask
sub cidr() 
{
  $imask = $_[0];
  @iarray = split( /\./, $imask );

  $mask = '';
  foreach (@iarray) {
    $_ = 255-$_;
    $mask.= "$rev.";
  }
  $mask =~ s/\.$//;

  $abin = unpack("B8", chr($iarray[0]));
  $bbin = unpack("B8", chr($iarray[1]));
  $cbin = unpack("B8", chr($iarray[2]));
  $dbin = unpack("B8", chr($iarray[3]));
  $total = $abin . $bbin . $cbin . $dbin;

  $bc=0;
  while ($total =~ m/1/g) {
    $bc++;
  }
}

## Build Command Argument to Execute
sub buildcmd() {
  if ($extra =~ /^redir$/) {
    if($rule ne '') {
      $args = "-t nat -A PREROUTING -i $int -j DNAT ";
      #$args = "-t nat -A PREROUTING -j DNAT ";
    }
    $daddr =~ s/\/\d+$//g;
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= "-d $saddr "};
    if($sport ne ''){$args.= "--dport $sport "};
    if($dport ne '' && $daddr ne ''){$args.= "--to $daddr:$dport "};
  } elsif($extra =~ /^portfw$/) {
    if($rule ne '') {
      $args = "-t nat -A PREROUTING -i $int -j REDIRECT ";
    }
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= ""};
    if($sport ne ''){$args.= "--dport $sport "};
    if($daddr ne ''){$args.= ""};
    if($dport ne ''){$args.= "--to-port $dport "};
  } elsif($extra =~ /^proute$/) {
    if($rule ne '') {
      $args = "-t nat -A PREROUTING -i $int ";
    }
    if($rule ne ''){$args.= "-j $rule "};
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= "-s $saddr "};
    if($sport ne ''){$args.= "--sport $sport "};
    if($daddr ne ''){$args.= "-d $daddr "};
    if($dport ne ''){$args.= "--dport $dport "};
  } elsif($extra =~ /^nat$/) {
    if($rule ne '') {
      $args = "-t nat -A POSTROUTING -o $int -j MASQUERADE ";
    }
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= "-s $saddr "};
    if($sport ne ''){$args.= "--sport $sport "};
    if($daddr ne ''){$args.= "-d $daddr "};
    if($dport ne ''){$args.= "--dport $dport "};
  } elsif($extra =~ /^snat$/) {
    if($rule ne '') {
      $args = "-t nat -A POSTROUTING -o $int -j SNAT ";
    }
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= "-s $saddr "};
    if($sport ne ''){$args.= "--sport $sport "};
    if($daddr ne ''){$daddr =~ s/\/32$//; $args.= "--to $daddr "};
    #if($dport ne ''){$args.= ":$dport "};
  } elsif($extra =~ /^dnat$/) {
    if($rule ne '') {
      $args = "-t nat -A PREROUTING -i $int -j DNAT ";
    }
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= "-s $saddr "};
    if($sport ne ''){$args.= "--sport $sport "};
    if($daddr ne ''){$args.= "-d $daddr "};
    if($dport ne ''){$args.= "--dport $dport "};
  } else {
    if($int ne ''){$args = "-A $tname "};
    if($rule ne ''){$args.= "-j $rule "};
    if($proto ne ''){$args.= "-p $proto "};
    if($saddr ne ''){$args.= "-s $saddr "};
    if($proto eq 'icmp') {
      #if($sport ne ''){$args.= "--icmp-type $sport "};
    } else {
      if($sport ne ''){$args.= "--sport $sport "};
    }
    if($daddr ne ''){$args.= "-d $daddr "};
    if($proto eq 'icmp') {
      if($dport ne ''){$args.= "--icmp-type $dport "};
    } else {
      if($dport ne ''){$args.= "--dport $dport "};
    }
    if($extra ne '') {
      if ($extra eq 'established') {
        $args.="-m state --state ESTABLISHED,RELATED";
      } elsif($extra eq 'log') {
        $logargs = $args;
        $logargs =~ s/ ACCEPT / LOG /g;
        $logargs =~ s/ DROP / LOG /g;
        $logargs =~ s/ REJECT / LOG /g;
        $logargs =~ s/ MASQ / LOG /g;
      } else {
        $args.= "$extra";
      }
    }
  }
  # End of Linux Conversion
}

1;
