#!/usr/bin/perl
# Merge the data produced from extract-sameparty.pl and the DIME
# recipients file (filtered to include only CA and only 2012 and
# later) to produce a file that has a list of races in which both
# candidates in the general election are from the same party, the
# names of those two candidates, their vote shares in the general
# election and in the primary election, if an opposite party candidate
# was on the ballot, vote share of the opposite party, and their
# respective DIME scores.
use strict;

my %dimes;
open IN, "dime_recip_ca_2012_2014.csv";
# Get the list of columns
$_ = <IN>;
chomp;
my %cols;
my @f = split /,/; # Since no column descriptions have commas, this works
foreach my $i (0..$#f) {
    # Remove leading and trailing quote signs
    substr $f[$i], 0, 1, "";
    substr $f[$i], -1, 1, "";
    $cols{$f[$i]} = $i;
}
# Create a structure where top-level key is year, then seat type
# (federal:house, state:upper, state:lower). Next level is the
# district. After that is the candidates and a list of attributes.
my %racelist;
while (<IN>) {
    chomp;
    @f = split /,/;
    # Correctly parse the CSV
    for (my $i = 0; $i < $#f; $i++) {
	while ($f[$i] =~ /^\"/ and $f[$i] !~ /\"$/ and $i < $#f) {
	    $f[$i] .= ",$f[$i + 1]";
	    splice @f, $i + 1, 1;
	}
    }
    next unless ($f[$cols{seat}] =~ /federal:house|state:(upp|low)er/);
    my $rtype = $f[$cols{seat}];
    my $rdesc;
    # Use descriptors to match with data extracted from extract-sameparty
    if ($rtype =~ /house/) {
	$rdesc = "Reps";
    } elsif ($rtype =~ /upper/) {
	$rdesc = "Senators";
    } elsif ($rtype =~ /lower/) {
	$rdesc = "Assembly";
    }
    my $dist = $f[$cols{district}];
    $dist =~ s/\"//g;
    my $dime = $f[$cols{"recipient.cfscore"}];
    my $lname = $f[$cols{lname}];
    my $fname = $f[$cols{fname}];
    my $mname = $f[$cols{mname}];
    $lname =~ s/\"//g; $fname =~ s/\"//g; $mname =~ s/\"//g;
    my $yr = $f[$cols{cycle}];
    $racelist{$yr}{$rdesc}{$dist}{$lname} = [$lname, $fname, $mname, $dime];
}

# Merge this now with the vote data
open PAIRS, "same-party.csv";
open MERGED, '>', 'merged-data.csv';

print MERGED "Year;OType;District;Party;Cand1;Cand2;Gen1;Gen2;Pri1;Pri2;",
    "Opp;PriTotal;PriOpp;DIME1;DIME2\n";
while (<PAIRS>) {
    chomp;
    my @f = split /;/;
    last if ($f[0] == 2016); # DIME not available for 2016 yet.
    my @cnds = @f[4, 5];
    my $ddesc;
    if ($f[1] eq "Reps") {
	$ddesc = sprintf "CA%02d", $f[2];
    } else {
	$ddesc = sprintf "CA-%d", $f[2];
    }
    my $ref = $racelist{$f[0]}{$f[1]}{$ddesc};
    # Make a list of candidates with available DIME scores in the district
    # Use to compare against the names of the candidates in the general.
    my @dcands = keys %$ref;
    my $dlist = join '|', @dcands;
    my @dimes;
    foreach my $i (0, 1) {
	if (lc($cnds[$i]) =~ /($dlist)\b/) {
	    my $mat = $1;
	    $dimes[$i] = $ref->{$mat}[3] if
		(lc($cnds[$i]) =~ /$ref->{$mat}[1]\b/);
	}
	# If it does not get a match right away, ask the user
	# if any of the candidates from the seat match.
	if (! defined $dimes[$i]) {
	    print STDOUT "Does $cnds[$i] match any of:\n  0  None\n";
	    foreach my $cno (0..$#dcands) {
		printf "%3d  %s\n", $cno + 1,
		join(" ", @{$ref->{$dcands[$cno]}});
	    }
	    my $resp = <STDIN>;
	    while ($resp !~ /^\d+$/) {
		print STDERR "Invalid response!";
		$resp = <STDIN>;
	    }
	    if ($resp > 0 and $resp - 1 <= $#dcands) {
		$resp--;
		$dimes[$i] = $ref->{$dcands[$resp]}[3];
	    }
	}
    }
    # If a DIME score was found for both candidates, output the record
    print MERGED $_, ";$dimes[0];$dimes[1]\n";
}
