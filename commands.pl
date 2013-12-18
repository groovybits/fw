# Linux firewall commands

sub loadModules () 
{
  $mode = $_[0];
  if ($mode eq 'start') {
    `$cmd -P INPUT ACCEPT >/dev/null 2>&1`;
    `$cmd -P OUTPUT ACCEPT >/dev/null 2>&1`;
    if($forward==1){`$cmd -P FORWARD ACCEPT >/dev/null 2>&1`};
    `echo 1 > /proc/sys/net/ipv4/ip_forward`;

    foreach (@modules) {
      $fullmod = $_ . ".o";
      if ( -e "/lib/modules/$kernver/ipv4/$fullmod") {
        `insmod $_ >/dev/null 2>&1`;
      }
    }
  } elsif($mode eq 'stop') {
    while ($modules[0] ne '') {
      $mod = pop @modules;
      $fullmod = $mod . ".o";
      if ( -e "/lib/modules/$kernver/ipv4/$fullmod") {
        `rmmod $mod >/dev/null 2>&1`;
      }
    }
  }
}

sub getInterfaces() 
{
  open(NDEV, "/proc/net/dev");
  foreach (<NDEV>) {
    if ($_ =~ /:/) {
      chomp($_);
      $_ =~ s/:.*$//g;
      $_ =~ s/^\s+//g;
      push @interfaces, $_;
    }
  }
  foreach (@extra_interfaces) {
      push @interfaces, $_;
      if ( ! -e "$cfgdir/$db/interface/$_" ) {
        mkdir "$cfgdir/$db/interface/$_", 0700;
      }
  }
}

sub clearRules()
{
  # Clear out the firewall rules
  `$fls`;
  `$clr`;
  `$cmd -F -t nat >/dev/null 2>&1`;
  `$cmd -X -t nat >/dev/null 2>&1`;
}
1;
