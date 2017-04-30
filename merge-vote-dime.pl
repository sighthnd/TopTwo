#!/usr/bin/perl
# Merge the data produced from extract-sameparty.pl and extract-dime.pl
# to produce a file that has a list of races in which both candidates
# in the general election are from the same party, the names of those
# two candidates, their vote shares in the general election and in the
# primary election, and their respective DIME scores.
use strict;

my %dimes;
# Read in the DIME data for each year
# Generate a hash with keys of Year, Office type, and Candidate
# and values of DIME scores.
foreach my $yr (2012, 2014) {
    open IN, "cands$yr.csv";
    while (<IN>) {
	s/\r?\n$//;
	next if (/comm\d/);
	my @f = split /,/;
	# Exclude those not from offices of interest
	if ($f[$#f - 2] =~ /(state:(upper|lower)|federal:house)/) {
	    my $etype = $1;
	    my $rating = $f[$#f];
	    my $cand = uc $f[1];
	    my $fname;
	    if ($cand =~ /^\"/ and $cand !~ /\"$/) {
		$cand .= ",uc $f[2]";
	    }
	    $dimes{$yr}{$etype}{uc $cand} = [$_, $f[$#f]];
	}
    }
}

# Calculate some summary statistics about the DIME scores
my (%es);
foreach my $yr (2012, 2014) {
    foreach my $cham (keys %{$dimes{$yr}}) {
	foreach my $cand (keys %{$dimes{$yr}{$cham}}) {
	    foreach my $ref ($es{$yr}{$cham}, $es{$yr}{tot}, $es{tot}) {
		$ref->[0] += $dimes{$yr}{$cham}{$cand};
		$ref->[1] += $dimes{$yr}{$cham}{$cand} ** 2;
		$ref->[2]++;
	    }
	}
    }
}

# Print out the mean and standard deviation of the DIME score
# for each year/office combination.
foreach my $yr (2012, 2014) {
    print "For year $yr:\n";
    foreach my $cham (qw/federal:house state:upper state:lower/) {
	my $ex = $es{$yr}{$cham}[0] / $es{$yr}{$cham}[2];
	my $ex2 = $es{$yr}{$cham}[1] / $es{$yr}{$cham}[2];
	printf ("  $cham\t%7.3f avg, %7.3f std\n", $ex, $ex2 - $ex**2);
    }
    my $ex = $es{$yr}{tot}[0] / $es{$yr}{tot}[2];
    my $ex2 = $es{$yr}{tot}[1] / $es{$yr}{tot}[2];
    printf "  Year total\t%7.3f avg, %7.3f std\n", $ex, $ex2 - $ex**2;
}
my $ex = $es{tot}[0] / $es{tot}[2];
my $ex2 = $es{tot}[1] / $es{tot}[2];
printf "Overall total\t%7.3f avg, %7.3f std\n", $ex, $ex2 - $ex**2;

my %hists;
foreach my $cham (qw/federal:house state:upper state:lower/) {
    $hists{$cham} = [sort {$a <=> $b} (values(%{$dimes{2012}{$cham}}),
				       values(%{$dimes{2014}{$cham}}))];
    print "$cham, min $hists{$cham}[0], max $hists{$cham}[$#{$hists{$cham}}]\n";
}

# Merge the DIME data with the vote data.
open PAIRS, "same-party.csv";
my %ofcs = (Reps => "federal:house", Senators => "state:upper",
	    Assembly => "state:lower");
open MERGED, ">", "merged-data.csv";
while (<PAIRS>) {
    my @f = split /;/;
    my ($yr, $ofc, $dist, $par, $cand1, $cand2) = @f[0..5];
    last if ($yr == 2016);
    chomp;
    my @cdimes;
    # Get the DIME score for both candidates in the general.
    foreach my $cand ($cand1, $cand2) {
	# The candidate names in the DIME table are generally either
	# all upper-case or all lower-case while the vote data from
	# California present the names with first letters upper-case
	# and the rest lower-case. First necessity is to make them
	# the same so that the data will merge.
	$cand =~ s/ ([IV]{,3}|[JS][Rr])$//;
	my @words = split ' ', $cand;
	$words[$#words] =~ s/([a-z])([A-Z])/$1\\-\?$2/;
	my $typ = $ofcs{$ofc};
	# Sometimes there will be a difference between the two in including
	# middle names. This provides some degree of ability to manage.
	# For a few cases, it was necessary to manually merge.
	my @dlist = grep {/\b$words[$#words]\b/i and /\b$words[0]\b/i}
	keys %{$dimes{$yr}{$typ}};
	if (@dlist == 1) {
	    push @cdimes, $dimes{$yr}{$typ}{$dlist[0]}[1];
	} elsif (@dlist > 1) {
	    my $mat = shift @dlist;
	    my $score = $dimes{$yr}{$typ}{$mat}[1];
	    foreach $mat (@dlist) {
		if ($dimes{$yr}{$typ}{$mat}[1] != $score) {
		    $score = "";
		    last;
		}
	    }
	    push @cdimes, $score;
	} else {
	    push @cdimes, "";
	}
    }
    print MERGED $_, ";$cdimes[0];$cdimes[1]\n";
}
