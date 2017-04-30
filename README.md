# TopTwo
Testing the results of the "top two" voting system when both candidates are from the same party

This project tests the effect of allowing voters to rate candidates of the opposite party relative to each other. Ordinarily, voters can choose from among candidates of their own party (in the primary) or between one choice from their own party and one from the other (in the general election). This remains the case in open and in non-partisan primaries because while such voting systems theoretically give voters the right to express a preference for one of the opposite party's candidates, exercising that right means forgoing expressing a preference for one's own party's candidate.

Since voters of one party tend to be ideologically skewed from the overall electorate, that is the average Democrat is more liberal than the average voter and the average Republican more conservative, the primaries tend to favor candidates who are more liberal or conservative than the average voter. Conversely, if voters could express a preference within the opposing party, it should have a moderating influence.

In 2012, California adopted the top two non-partisan primary system in which the top two candidates, even if both are of the same party, advance to the general election. When both advancing candidates are from the same party, voters from the opposite party can express a preference for one over the other without the option of choosing a candidate from their own party. If this has a moderating effect, then in election cycles having candidates from both parties in the primary and only one party in the general election, the candidate who is closer to the ideological middle should get a higher share of the two-candidate vote in the general election than in the primary.

## Data
The vote data come from the California Secretary of State website. Included are elections for Congress and the State Senate and Assembly for 2012 and 2014. Election data were also downloaded for 2016, but there were no candidate ideological data for that year currently.

http://www.sos.ca.gov/elections/prior-elections/statewide-election-results/

The ideology data come from Adam Bonica's Database on Ideology, Money in politics, and Elections (DIME).

https://data.stanford.edu/DIME

## Files
explore-dime.ipynb 

Exploration of the distribution of DIME scores for 2012 and 2014


SamePartyTest.ipynb

Testing the correlation between the DIME scores and election results for elections in which both general election candidates are of the same party


extract-sameparty.pl

Perl code that extracted races from the spreadsheets from the California Secretary of State's websites where both candidates in the general election were from the same party and the vote totals in the general and primary.


extract-dime.pl

Perl code that extracted DIME data for each candidate


merge-vote-dime.pl

Perl code that merged the DIME scores from the output of extract-dime.pl with the vote data in the output from extract-sameparty.pl
