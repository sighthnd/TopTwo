#!/usr/bin/perl
use Spreadsheet::ParseExcel;
use strict;

open OUT, ">", "same-party.csv";
my $exc = Spreadsheet::ParseExcel->new;
foreach my $dir (2012, 2014, 2016) {
    # Includes the following elections for those three years:
    # Congress, State Senate, Assembly, general and primary
    opendir D, $dir;
    my @fils = grep {/\.xls$/} readdir D;
    closedir D;
    # Order the files so that the two Congress, two Senate, and two Assembly
    # files will be consecutive and so that the general will be first of them
    @fils = sort {&ot($a) cmp &ot($b) or &nst($a) <=> &nst($b)} @fils;
    my %dists;
    while (@fils) {
	print "$dir, $fils[0]\n";
	my ($type, $flag);
	# Select a pair of files, one general and one primary for an
	# election type.
	my $fil = shift @fils;
	my $filpri = shift @fils;
	if ($fil =~ /(assembly|reps|senators)/) {
	    $type = $1;
	}
	if ($dists{$type}) {
	    $flag = 1;
	}
	my $skip = 0;
	my $bkgen = $exc->Parse("$dir/$fil") or die $!;
	my $shgen = $bkgen->{Worksheet}[0];
	my $bkpri = $exc->Parse("$dir/$filpri") or die $!;
	my $shpri = $bkpri->{Worksheet}[0];
	my $dist;
	# Keep separate track of the row in the primary spreadsheet
	# from the general
	my $prir = 0;
	for (my $r = 0; $skip < 20; $r++) {
	    if ($shgen->get_cell($r, 0)) {
		$skip = 0;
		# Each district is identified with the first column
		# being the district number and the following row blank.
		# After that is the names of the candidates and their parties.
		if ($shgen->get_cell($r, 0)->value =~ /(\d+).*District/) {
		    $dist = $1;
		    # Skip if there is only one candidate
		    next unless ($shgen->get_cell($r+3, 2));
		    if ($shgen->get_cell($r+3, 1)->value eq
			$shgen->get_cell($r+3, 2)->value) {
			# Check if party is the same for both, otherwise ignore
			print OUT "$dir;", ucfirst($type), ";$dist;";
			my @cands;
			# Used when looking for the candidates in the
			# primary sheet
			my $party = $shgen->get_cell($r+3, 2)->value;
			print OUT "$party;";
			# Get the names of the candidates and their vote totals
			foreach my $c (1, 2) {
			    my $cname = $shgen->get_cell($r+2, $c)->value;
			    $cname =~ s/[\r\n]/ /g;
			    $cname =~ s/^\s*//;
			    $cname =~ s/\s*$//;
			    $cname =~ s/\s+/ /g;
			    $cname =~ s/[^A-Za-z ]//g;
			    print OUT "$cname;";
			    push @cands, $cname;
			}
			my $str;
			my $opp = 'N';
			my $oth = $party =~ /DEM/ ? "REP" : "DEM";
			# Record the vote totals for each candidate
			while (!$str) {
			    $r++;
			    if ($shgen->get_cell($r, 0) and
				$shgen->get_cell($r, 0)->value =~
				/^District /) {
				$str = $shgen->get_cell($r, 0)->value;
			    }
			}
			print OUT ($shgen->get_cell($r, 1)->value, ";",
				   $shgen->get_cell($r, 2)->value, ";");
			# Advance in the primary spreadsheet to the current
			# district
			while (!$shpri->get_cell($prir, 0) or
			       $shpri->get_cell($prir, 0)->value !~ 
			       /\b$dist\D+District/) {
			    $prir++;
			}
			# Get the primary vote totals for the candidates
			# that advanced
			my ($candr, $voter, @pvotes);
			# Identify the first row of candidates
			$candr = $prir + 2;
			# Identify where the data for that row end
			# This is at the row that starts "District Totals"
			$voter = $candr + 2;
			while ($shpri->get_cell($voter, 0)->value !~
			       /^District/) {
			    $voter++;
			}
		      DIST:
			while (!$pvotes[0] or !$pvotes[1] or $opp eq 'N') {
			    for (my $c = 1; $shpri->get_cell($candr, $c);
				 $c++) {
				# Exclude candidates not of the party
				# in the general
				my $pstr = $shpri->get_cell($candr+1, $c)->
				    value;
				$opp = 'Y' if ($pstr =~ /^$oth/ and
					       $pstr !~ m%W/I%);
				next unless ($pstr =~ /^$party/);
				# Get the candidate name
				my $cname = $shpri->get_cell($candr,$c)->value;
				$cname =~ s/^\s*//;
				$cname =~ s/\s*$//;
				$cname =~ s/[\r\n]/ /g;
				$cname =~ s/\s+/ /g;
				$cname =~ s/[^A-Za-z ]//g;
				foreach my $ind (0, 1) {
				    # Compare to each candidate in the general
				    next unless (&match($cname, $cands[$ind]));
				    $pvotes[$ind] =
					$shpri->get_cell($voter, $c)->value;
				}
				last if ($pvotes[0] and $pvotes[1] and
					 $opp eq 'Y');
			    }
			    # Check that both candidates were found
			    # If not, check the next row of candidates
			    if (!$pvotes[0] or !$pvotes[1] or $opp eq 'N') {
				$candr = $voter + 2;
				while (!$shpri->get_cell($candr, 1) or
				       $shpri->get_cell($candr, 1)->value !~
				       /\S/) {
				    if ($candr - $voter > 15 or
					($shpri->get_cell($candr, 0) and
					 $shpri->get_cell($candr, 0)->value =~
					 /District/)) {
					last DIST;
				    }
				    $candr++;
				}
				$voter = $candr + 2;
				while ($shpri->get_cell($voter, 0) and
				       $shpri->get_cell($voter, 0)->value !~
				       /^District/) {
				    $voter++;
				}
			    }
			}
			print OUT "$pvotes[0];$pvotes[1];$opp\n";
		    }
		}
	    } else {
		$skip++;
	    }
	}
    }
}

# The files are named <num>-<type>.xls
# where for any <type>, the number <num> is lower for
# the general election than for primary. These two
# subroutines thus identify the office <type> and the
# election type.
sub nst {
    # Return the number at the start of the file name
    # The general has the lower number for all examples in
    # this set
    my ($str) = @_;
    if ($str =~ /^(\d+)/) {
	return $1;
    } else {
	return 0;
    }
}

sub ot {
    # Return the string identifying the office type
    # Many of the files have "us" or "state" in the <type>, but some do
    # not. Choosing the second or third element allows selection of
    # whichever one is office type minus "us" or "state".
    my ($str) = @_;
    $str =~ s/\.xls$//;
    my @words = split '-', $str;
    my $ret = $words[2] || $words[1];
    return $ret;
}

sub match {
    # Allows some degree of fuzzy matching of candidate names
    # Specifically, if one instance instance a middle name and the other
    # does not, this will match on the names that agree
    my ($str1, $str2) = @_;
    return 1 if ($str1 eq $str2);
    my @w1 = split ' ', $str1;
    my @w2 = split ' ', $str2;
    while (@w1 and @w2) {
	if ($w1[0] eq $w2[0]) {
	    shift @w1;
	    shift @w2;
	}
	if ($w1[$#w1] eq $w2[$#w2]) {
	    pop @w1;
	    pop @w2;
	}
	return 0 if (@w1 and @w2 and $w1[0] ne $w2[0] and
		     $w1[$#w1] ne $w2[$#w2]);
    }
    return 1;
}
