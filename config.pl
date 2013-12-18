# Configuration

$version = '0.2.0';
$debug = 1;
$forward = 1;
@extra_interfaces = ('');
$db = "base";
$runcfg = "$db/running-config";

$ENV{'PATH'} = "/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin";

$kernver = `cat /proc/sys/kernel/osrelease`;
chomp($kernver);

$cmd = "iptables";
@tables = ('INPUT', 'OUTPUT', 'FORWARD');
@modules = ('ip_tables','iptable_filter','ip_conntrack',
            'ip_conntrack_ftp','ipt_state','iptable_mangle',
            'iptable_nat','ipt_MASQUERADE',
            'ip_nat_ftp','ip_queue','ipt_REDIRECT','ipt_limit',
            'ipt_MIRROR ','ipt_LOG','ipt_REJECT');
$fls = "$cmd -F";
$clr = "$cmd -X";
$pffls = "$pfcmd -f";

1;
