# Command Line Interface
sub CLI() 
{
  $motd = "Type ? for help.\n";
  print "$motd\n";
  while($input !~ /^exit$/ || $mode =~ /^\(config\)/) {
    $prompt = "$ENV{'HOSTNAME'}$mode# ";
    $mode =~ s/\)//g;
    $mode =~ s/\(//g;
    print "$prompt";
    $input = <STDIN>;
    
    # Interpret Input
    $cfg='';
    if ($input =~ /c.*t.*/ || $mode =~ /^config/) {
      $mode = "(config)";
      if ($input =~ /^exit/) {
        $input = "";
        $mode = "";
      } elsif ($input =~ /^\?$/) {
        print "Commands:\n";
        print " access-list\tip access-list\n"; 
        print "\n";
        next;
      } elsif ($input =~ /access-list/) {
        $input =~ s/^\s+//g;
        $input =~ s/\s+$//g;
        $input =~ s/\n+$//g;
        if ($input =~ s/^no //g) {
          $no = 1;
        }
        @line = split( / /, $input );
        shift(@line);
        ($iname, $type) = split( /_/, $line[0]);
        chomp($iname); chomp($type);
        if ($type eq 'i') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[0]";
          $drule = "input";
        } elsif ($type eq 'o') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[1]";
          $drule = "output";
        } elsif ($type eq 'f') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[2]";
          $drule = "forward";
        }  else {
          print "Error encounterd\n";
          print "$ipath wrong file=$file type=$type iname=$iname\n";
          print "Line: $input\n";
          next;
        }
        if ($debug == 1) {
          if ($no == 1) {
            print "Deleting: $ipath\n";
          } else {
            print "Adding to: $ipath\n";
          }
          foreach (@line) {
            print "$_ ";
          }
          print "\n";
        }
        open(CONFIG, ">>$ipath");
        select(CONFIG);
        if ($no == 0) {
          shift(@line);
          $bldline = '';
          foreach (@line) {
            $bldline.= "$_ ";
          }
          $bldline =~ s/\s+$//g;
          print "!\n$bldline\n";
          close(CONFIG);
        } else {
          $no = 0;
          close(CONFIG);
          unlink("$ipath");
        }
        select(STDOUT);
      } elsif ($input !~ /^$/ && $input !~ /c.*t.*/) {
        print "Invalid input\n";
      }
    } elsif ($input =~ /w.*\st/) { 
      ## WRITE OUT CONFIGURATION
      print "Building configuration...\n";

      $cfg.= "Current configuration:\n";
      $cfg.= "!\n";
      $cfg.= "! Last configuration change at $chgdate\n";
      $cfg.= "!\n";
      $cfg.= "version $version\n";
      $cfg.= "!\n";
      $cfg.= "hostname $ENV{'HOSTNAME'}\n";
      $cfg.= "!\n";
      $cfg.= "!\n";
      $cfg.= "!\n";
      $cfg.= "!\n";
      $cfg.= "!\n";
      foreach $int (@interfaces) {
        if ($int ne '') {
          ;; 
        } else {
          next;
        }
        $cfg.= "interface $int\n";
        foreach $table (@tables) {
          if ($table eq 'INPUT' || $table eq 'input') {
            $tname = "$int" . "_i";
          } elsif( $table eq 'OUTPUT' || $table eq 'output') {
            $tname = "$int" . "_o";
          } elsif( $table eq 'FORWARD' || $table eq 'forward') {
            $tname = "$int" . "_f";
          }
          if ( -f "$cfgdir/$db/interface/$int/$table" ) {
            $cfg.= " access-group $tname $table\n";
            push @cpaths, "$tname:$cfgdir/$db/interface/$int/$table";
          }
        }
        $cfg.= "!\n";
      }

      # Write out access-tables
      foreach $cpath (@cpaths) {
        ($name, $cpath) = split( /:/, $cpath);
        open(CFILE, "$cpath");
        @lines = <CFILE>;
        close(CFILE);
        foreach $line (@lines) {
          if ($line !~ /^\#/ && $line !~ /^\!/ && $line !~ /^$/) {
            $cfg.= "access-list $name $line";
          }
        } 
        $cfg.= "!\n";
      }
      $cfg.= "!\n";
      if ( ! -e "/tmp/fw.cfg" ) {
        open(TMP, ">/tmp/fw.cfg");
        print TMP $cfg;
        close(TMP);
        system("cat /tmp/fw.cfg | more");
        unlink("/tmp/fw.cfg");
      } else {
        print "Error: file /tmp/fw.cfg exists...\n";
        sleep 3;
        next;
      }
    } elsif ($input =~ /e.*\s.*_.*/) {
      ## EDIT CONFIGURATION OF A TABLE
      ($junk, $file) = split( / /, $input);
      ($iname, $type) = split( /_/, $file);
      chomp($iname); chomp($type);
      if ($type eq 'i') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[0]";
          $drule = "input";
      } elsif ($type eq 'o') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[1]";
          $drule = "output";
      }  elsif ($type eq 'f') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[2]";
          $drule = "forward";
      }  else {
        print "Error encounterd\n";
        print "$ipath wrong file=$file type=$type iname=$iname\n";
        next;
      }
      print "Editing the $drule rules for interface $iname\n";
      sleep 1;
      system("vi $ipath");
    } elsif ($input =~ /a.*\s.*_.*/) {
      chomp($input);
      print "Creating interface $input...\n";
      ## CREATE An INTERFACE TABLE
      ($junk, $file) = split( / /, $input);
      ($iname, $type) = split( /_/, $file);
      chomp($iname); chomp($type);
      if ($type eq 'i') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[0]";
      } elsif ($type eq 'o') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[1]";
      }  elsif ($type eq 'f') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[2]";
      }  else {
        print "Error encounterd\n";
        print "$ipath wrong file=$file type=$type iname=$iname\n";
        next;
      }
      sleep 1;
      system("mkdir -p $cfgdir/$db/interface/$iname");
      system("touch $ipath");
    } elsif ($input =~ /d.*\s.*_.*/) {
      chomp($input);
      print "Deleting interface $input...\n";
      ## DELETE An INTERFACE TABLE
      ($junk, $file) = split( / /, $input);
      ($iname, $type) = split( /_/, $file);
      chomp($iname); chomp($type);
      if ($type eq 'i') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[0]";
      } elsif ($type eq 'o') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[1]";
      }  elsif ($type eq 'f') {
          $ipath = "$cfgdir/$db/interface/$iname/$tables[2]";
      }  else {
        print "Error encounterd\n";
        print "$ipath wrong file=$file type=$type iname=$iname\n";
        next;
      }
      $confirm = '';
      print "Are you sure you want to delete $input [y|n]: ";
      $confirm = <STDIN>;
      chomp($confirm);
      if ($confirm eq 'y') {
        #print "Backing up files to \"$cfgdir/$db/.iname.bak\"\n";
        #sleep 1;
        #system("cp -rpda $cfgdir/$db/$iname/ $cfgdir/$db/.$iname.backup");
        system("rm -f $cfgdir/$db/interface/$iname/*");
        system("rmdir $cfgdir/$db/interface/$iname/");
      }
    } elsif ($input =~ /^\?$/) {
      ## HELP COMMAND
      print "\n";
      print " Interface and tablename format is:\n";
      print "  eth0_i for INPUT   through eth0\n";
      print "  eth0_o for OUTPUT  through eth0\n";
      print "  eth0_f for FORWARD through eth0\n";
      print " \n";
      print " config terminal             -- Enter Configuration Mode\n";
      print " \n";
      print " write terminal              -- Show Configuration\n";
      print " edit [interface_dir]        -- Edit Configuration\n";
      print " add [interface_dir]         -- Add Network Interface\n";
      print " delete [interface_dir]      -- Delete Network Interface\n";
      print " \n";
      print " start 			  -- Start Firewall\n";
      print " stop 			  -- Stop Firewall\n";
      print " reload			  -- Reload Firewall\n";
      print "\n";
    } elsif ($input =~ /^reload$/ ||
             $input =~ /^start$/) 
    {
      chomp($input);
      $confirm = '';
      print "Are you sure you want to $input the firewall [y|n]: ";
      $confirm = <STDIN>;
      chomp($confirm);
      if ($confirm eq 'y') {
        system("$0 start");
      }
    } elsif ($input =~ /^stop$/) {
      $confirm = '';
      print "Are you sure you want to stop the firewall [y|n]: ";
      $confirm = <STDIN>;
      chomp($confirm);
      if ($confirm eq 'y') {
        system("$0 stop");
      }
    } elsif ($input !~ /^$/ && $input !~ /^exit$/) {
      print "Invalid input\n";
    } elsif ($input =~ /^exit$/) {
      print "Logout of config.\n\n";
      exit 0;
    }
  }
  exit 0;
}
1;
