use Config;
# vim: set sw=4 ts=4 si et:
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($Config{'osname'} eq 'VMS' or
            $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

my $VERSION="unknown";
if (-r "../Tagreader.pm"){ # get version
    open(F,"../Tagreader.pm")||die;
    while(<F>){
        if (/\$VERSION *= *(.+)/){
            $VERSION=$1;
            $VERSION=~s/[^\.\d]//g;
        }
    }
    close F;
}

print OUT "$Config{'startperl'} -w
my \$VERSION = \"$VERSION\";
";


print OUT <<'!NO!SUBS!';
# vim: set sw=4 ts=4 si et:
# Copyright: GPL, Author: Guido Socher
#
use strict;
use vars qw($opt_l $opt_a $opt_h $opt_A $opt_W);
use Getopt::Std;
use HTML::Tagreader;
#
sub help();
sub showonefile($);
sub linktype($);
#
getopts("haAlW")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);
if ($opt_a){
    $opt_l=1;
}

for my $f (@ARGV){
    if ( -r "$f" ){
        showonefile($f);
    }else{
        warn "ERROR: can not read $f\n";
    }
}
# 
# list tags in exactly one file 
#
sub showonefile($){
    my $infile=shift;
    my @tag;
    my $linktype; # one of: name href src background
    my ($waitclosetag,$origtag,$aline,$atag,$path,$tmp,$ltype,$line,$waitcount);

    my $p=new HTML::Tagreader "$infile";
    print "$infile\n" unless($opt_l);
    $waitclosetag=0;
    $waitcount=0;
    $atag="";
    while(@tag = $p->getbytoken(!$opt_W)){
        # read out the tags, note something like: 
        # <a name="xxxx" href="...."> .... </a>
        # is valid
        #
        $origtag=$tag[0];
        if($tag[1] eq "" || $tag[1] eq "!--"){ # not a tag, but text or a comment
            if ($waitclosetag && $opt_a){
                $atag.=$tag[0];
            }
            next;
        } 
        if ($waitclosetag){
            $tag[0]=~s/\s+/ /g; # kill newline and double space
            $atag.=$tag[0];
            $waitcount++;
            if ($tag[1] eq "/a"){
                $waitclosetag=0;
                print "$infile:$aline: $atag\n";
                $atag="";
                next;
            }
            if ($waitcount > 10){
                print STDERR "$infile:$aline: Warning \"<a ...\" starting not terminated\n" unless($opt_W);
                $waitclosetag=0;
                $waitcount=0;
                if ($opt_l){
                    print "$infile:$aline: $atag\n";
                }else{
                    print "$atag\n";
                }
                $atag="";
            }
        }
        # we search for " href", " src", " background": 
        unless($tag[0]=~/\ssrc|\shref|\sbackground/i){
            next;
        } 
        $line=$tag[2];
        $tag[0]=~s/\s+/ /g; # kill newline and double space
        if ($tag[0]=~/ (href|src|background) ?= ?([^ >]+)/i){
            $linktype=$1;
            $path=$2;
            $path=~s/[\'\"]//g;
            $ltype=linktype($path);
            if (! $opt_A ){
                next if ($ltype ne "rel");
            }
            if ($tag[1] eq "a" && $opt_a ){
                if ($waitclosetag){
                    print STDERR "Warning: $infile:$line: \"<a ...\" starting at line $aline not terminated\n" unless($opt_W);
                    print "$infile:$aline: $atag\n";
                }
                # wait for closing "</a>"
                $waitcount=0;
                $aline=$line;
                $waitclosetag=1;
                $atag=$tag[0];
            }else{
                # print now
                if ($opt_l){
                    print "$infile:$line: $tag[0]\n";
                }else{
                    print "$path\n";
                }
            }
        }else{
            print STDERR "$infile:$line: Warning, broken link $tag[0]\n" unless($opt_W);
        }
    }
}
#----------------------------------
# find out if this is an abs link (proto://, file:, rel, /absfile)
sub linktype($){
    my $pathstr=shift; # no quotes must be arround the path
    if ($pathstr=~ m=^/=){
        return('/absfile');
    }elsif ($pathstr=~ m=^\.=){
        return('rel'); # may still contain a ref to named anchor
    }elsif ($pathstr=~ m=^\#=){
        return('anchor'); # relative anchor in the same file!
    }elsif ($pathstr=~ m=^file:=i){
        return('file:');
    }elsif ($pathstr=~ m=^\w+://=i){
        return('proto://');
    }elsif ($pathstr=~ m=^\w+:=i){
        return('proto:'); # mailto: or javascript:
    }else{
        return('rel');
    }
}
#----------------------------------
sub help(){
print "llnk -- list links in html files

USAGE: llnk [-h] [-AalW] html-files

Without option -A llnk will list only relative links.
The idea of this program is that you run 
tar cvf pages.tar `llnk index.html something.html`
in order to include files that are referenced by index.html and
something.html. 

With the option -A you can use llnk to inspect the links in
html files.

OPTIONS: 
         -h this help

         -a list for <a href=...> tags everything until </a>
         This option implies (-l). You can not use this option
         in combination with tar to pack files together. This is 
         more to look at the links of a webpage.

         -A list all href=...,  src=..., and background=... tags
         whether they are relative or not.

         -l print with filename, line number and entire tag. Note that errors
         and warnings are always printed with filename and line numbers.
         If -l is given then the file names from the command line are
         not included unless they appear in one of the files as
         links. You can not use this in combination with tar to pack 
         files together.

         -W do not print warnings about html errors (not terminated
         tags etc ...).

EXAMPLE:
 pack a tar file:
 tar cvf pages.tar `llnk index.html something.html`

 inspect a html file:
 llnk -Al something.html

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

llnk -- list links in html files

=head1 SYNOPSIS

USAGE: llnk [-h] [-AalW] html-files

=head1 DESCRIPTION

Without option -A llnk will list only relative links.
The idea of this program is that you run 
tar cvf pages.tar `llnk index.html something.html`
in order to include files that are referenced by index.html and
something.html. 

With the option -A you can use llnk to inspect the links in
html files.

=head1 OPTIONS

-h this help

-a list for <a href=...> tags everything until </a>
This option implies (-l). You can not use this option
in combination with tar to pack files together. This is 
more to look at the links of a web page.

-A list all href=...,  src=..., and background=... tags
whether they are relative or not.

-l print with filename, line number and entire tag. Note that errors
and warnings are always printed with filename and line numbers.
If -l is given then the file names from the command line are
not included unless they appear in one of the files as
links. You can not use this in combination with tar to pack 
files together.

-W do not print warnings about html errors (not terminated
tags etc ...).

=head1 EXAMPLE

pack a tar file:
tar cvf pages.tar `llnk index.html something.html`

inspect a html file:
llnk -Al something.html

=head1 AUTHOR

xlnk is part of the Tagreader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=cut
!NO!SUBS!

