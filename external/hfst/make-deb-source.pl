#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
use utf8;
use strict;
use warnings;
BEGIN {
	$| = 1;
	binmode(STDIN, ':encoding(UTF-8)');
	binmode(STDOUT, ':encoding(UTF-8)');
}
use open qw( :encoding(UTF-8) :std );

use Getopt::Long;
my %opts = (
	'm' => 'Tino Didriksen <mail@tinodidriksen.com>',
	'e' => 'Tino Didriksen <mail@tinodidriksen.com>',
	'dv' => 1,
	'fv' => 1,
);
GetOptions(
	'm=s' => \$opts{'m'},
	'e=s' => \$opts{'e'},
	'distv=i' => \$opts{'dv'},
	'flavv=i' => \$opts{'fv'},
);

my %distros = (
	'wheezy' => 'debian',
	'jessie' => 'debian',
	'sid' => 'debian',
	'precise' => 'ubuntu',
	'saucy' => 'ubuntu',
	'trusty' => 'ubuntu',
	'utopic' => 'ubuntu',
);

print `rm -rf /tmp/autopkg.*`;
print `mkdir -pv /tmp/autopkg.$$`;
chdir "/tmp/autopkg.$$" or die "Could not change folder: $!\n";

print `svn export http://svn.code.sf.net/p/hfst/code/trunk/hfst3/configure.ac`;
my $major = 0;
my $minor = 0;
my $patch = 0;
my $revision = `svn log -q -l 1 http://svn.code.sf.net/p/hfst/code/trunk/hfst3/ | egrep -o '^r[0-9]+' | egrep -o '[0-9]+'` + 0;
{
	local $/ = undef;
	open FILE, 'configure.ac' or die "Could not open configure.ac: $!\n";
	my $data = <FILE>;
	my ($version) = ($data =~ m@AC_INIT.*?\[([\d.]+)\]@s);
	if ($version =~ m@^(\d+)\.(\d+)$@) {
		$major = $1;
		$minor = $2;
	}
	elsif ($version =~ m@^(\d+)\.(\d+)\.(\d+)$@) {
		$major = $1;
		$minor = $2;
		$patch = $3;
	}
	close FILE;
}

my $version = "$major.$minor.$patch.$revision";
my $date = `date -u -R`;

print `svn export http://svn.code.sf.net/p/hfst/code/trunk/hfst3/ 'hfst-$version'`;
`find 'hfst-$version' ! -type d | LC_ALL=C sort > orig.lst`;
print `tar -jcvf 'hfst_$version.orig.tar.bz2' -T orig.lst`;
print `svn export https://svn.code.sf.net/p/apertium/svn/branches/packaging/external/hfst/debian/ 'hfst-$version/debian/'`;

foreach my $distro (keys %distros) {
	my $chver = $version.'-';
	if ($distros{$distro} eq 'ubuntu') {
		$chver .= "0ubuntu";
	}
	$chver .= $opts{'dv'}."~".$distro.$opts{'fv'};
	my $chlog = <<CHLOG;
hfst ($chver) $distro; urgency=low

  * Automatic build - see changelog via: svn log http://svn.code.sf.net/p/hfst/code/trunk/hfst3/

 -- $opts{e}  $date
CHLOG

	`cp -al 'hfst-$version' 'hfst-$chver'`;
	unlink "hfst-$chver/debian/changelog";
	open FILE, ">hfst-$chver/debian/changelog" or die "Could not write to debian/changelog: $!\n";
	print FILE $chlog;
	close FILE;
	print `dpkg-source '-DMaintainer=$opts{m}' '-DUploaders=$opts{e}' -b 'hfst-$chver'`;
	chdir "hfst-$chver";
	print `dpkg-genchanges -S -sa '-m$opts{m}' '-e$opts{e}' > '../hfst_$chver\_source.changes'`;
	chdir '..';
	print `debsign 'hfst_$chver\_source.changes'`;
}

chdir "/tmp";
