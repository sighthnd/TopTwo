#!/usr/bin/perl
use strict;

# The latest year for DIME data is 2014
foreach my $yr (2012, 2014) {
    open OUT, "> dime$yr-cands.csv";
    open IN, "gzip -cd $yr/contribDB_$yr.csv.gz |" or die $!;
    $_ = <IN>;
    while (<IN>) {
	my @f = split /,/;
	# Do the equivalent of reading in a CSV
	for (my $i = 0; $i < $#f; $i++) {
	    while ($f[$i] =~ /^\".*[^\"]$/ and $i < $#f) {
		$f[$i] .= ",$f[$i + 1]";
		splice @f, $i + 1, 1;
	    }
	}
	# Limits the output to California and selects the following columns:
	# Cycle, Recipient Name, Recipient ID, Party, Type, State, Seat,
	# Election Type, Candidate DIME Score
	print OUT join(",", @f[0,22..28,45]) if ($f[26] =~ /CA/);
    }
}
