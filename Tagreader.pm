package HTML::Tagreader;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = '0.05';

bootstrap HTML::Tagreader $VERSION;

1;
__END__
# Below is the documentation for your module. 

=head1 NAME

Tagreader - Perl extension module for reading html/sgml/xml tags

=head1 SYNOPSIS

  use HTML::Tagreader;
  # open then file and get an obj-ref:
  my $p=new HTML::Tagreader "filename";

  # set to zero or undef to omit warnings about html error:
  $showerrors=1; 

  # get only the tags:
  my $tag = $p->gettag($showerrors);
    # or
  my ($tag,$linenumber) = $p->gettag($showerrors);

  # get the entire file split into tags and text parts:
  my $tag = $p->getbytoken($showerrors);
    # or
  my ($tag,$tagtype,$linenumber) = $p->getbytoken($showerrors);

=head1 DESCRIPTION

The module implements a fast and small object oriented way of
processing any kind of html/sgml/xml files by tag.

The getbytoken(0) is similar to while(<>) but instead of reading lines 
it reads tags or tags and text. 

Here is a program that list all href tags
in a html file together with it line numbers:

	use Tagreader;
	my $p=new Tagreader "file.html";
	my @tag;
	while(@tag = $p->gettag(1)){
		if ($tag[0]=~/ href ?=/i){
			# remove optional space before the equal sign:
			$tag[0]=~s/ ?= ?/=/g;
			print "line: $tag[1]: $tag[0]\n";
		}
	}

Here is a program that will read a html file tag
wise:

	use Tagreader;
	my $p=new Tagreader "file.html";
	my @tag;
	while(@tag = $p->getbytoken(1)){
		if ($tag[1] eq ""){
			print "line: $tag[2]: not a tag (some text), \"$tag[0]\"\n\n";
		}else{
			print "line: $tag[2]: is a tag, $tag[0]\n\n";
		}
	}

=head2 new HTML::Tagreader $file;

Returns a reference to a Tagreader object. This reference can
be used with gettag() or getbytoken() to read the next tag.

=head2 gettag($showerrors);

Returns in an array context tag and line number. In a
scalar context just the next tag.
 
An empty string or and empty array is returned if the file contains
no further tags. html/xml comments and any tags inside the comments
are ignored.

The returned tag string has all white space (tab, newline...) reduced to just a
single space otherwise upper and lower case, quotes etc are as in the
original file. The line numbers are those where the tag
starts.

You must provide 0 (or undef) or 1 as an argument to gettag. 
If 0 is provided then gettag will not print any errors if it finds
a syntax error in the html/sgml/xml code.

Currently only the following error cases are implemented:

- A starting '<' was found but no closing '>' after 300 characters

- A single '<' was found which was not followed by [!/a-zA-Z]. Such
a '<' should be written as &lt;

=head2 getbytoken($showerrors);

Returns in an array context tag, tagtype (a, br, img,...)  and line number. 
In a scalar context just the next tag.

An empty string or and empty array is returned if the file contains
no further tags. 

getbytoken() should be used to process a html file and possibly
modify tags. As opposed to gettag() the getbytoken() does not
remove newline or space from the data. 

tagtype is always lower case. The tagtype is the string starting
the tag such as "a" in <a href=""> or "!--" in <!-- comment -->.
tagtype is empty if this is not a tag (normal text or newline).

You must provide 0 (or undef) or 1 as an argument to getbytoken. 
If 0 is provided then gettag will not print any errors if it finds
a syntax error in the html/sgml/xml code.

Currently only the following error cases are implemented:

- A starting '<' was found but no closing '>' after 300 characters

- A single '<' was found which was not followed by [!/a-zA-Z]. Such
a '<' should be written as &lt;

=head2 Limitations

No text must be longer than 7k without some kind
of tag inbetween.

If you need a more sophisticated interface you might want to take a look at
HTML::Parser. HTML:Tagreader is fast generic and straight forward to use.

=head1 COPYRIGHT

Copyright (c) Guido Socher [guido(at)linuxfocus.org]

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

homepage of this program: http://linuxfocus.org/~guido/ 

perl(1) HTML::Parser(3)

=cut
