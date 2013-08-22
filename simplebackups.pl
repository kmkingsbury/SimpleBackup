#! /usr/bin/perl -w
#
#  Kevin M Kingsbury (kkingsbury@gmail.com) 2003 
#
#  simplebackups.pl
#  Reads a backups.txt file and creates tar archives of directories.
#  x days worth are kept as well as the 1st of each month.
#  I typically install it as cronjob:
#  00 3 * * * /root/bin/simplebackups.pl
# 
#  Creates tarballs that have a name like: something.20130822.tar.gz
#
use strict;
use Data::Dumper;

# Settings:
my $numofbackups = 7;
my $config = "simplebackuplist.txt";


my ($day, $mon, $year) = (localtime)[3..5];
my $date = sprintf("%04d%02d%02d", ($year+1900), ($mon+1), $day);
my (@srcs, @dests, @prefixs);

#Read Config File
open (my $CONF, $config) || die "Cannnot up Configuration file: $config :$!";
while (<$CONF>){
    chomp;
    if (! /^\#/){ #ignore # as comments
        my @items = drop_empty(split /\s/);
        if (@items == 3){
            push @srcs, $items[0];
            push @dests, $items[1];
            push @prefixs, $items[2];
        }
    }
}
close ($CONF);


# Iterate through config
for (my $z = 0; $z < @srcs; $z++){
    my $destloc = $dests[$z];
    my $srcloc = $srcs[$z];
    my $prefix = $prefixs[$z];
    print "Backing up $prefix\n";

    #Create Backup
    my $exec = "/bin/tar -cvf " . $destloc . "$prefix." . $date .".tar $srcloc";
    `$exec`;
    $exec = "/usr/bin/gzip -f ". $destloc . "$prefix." . $date .".tar";
    `$exec`;

    #Sort Listing
    opendir(my $DIR, "$destloc") || die "Cannot Read Destination Directory\n";
    my @Filenames = grep(/$prefix\.[0-9]{8}\.tar.gz/, readdir $DIR);
    closedir($DIR);

    my ($keep, $cnt) = qw(0 0);
    my @tmpfile = ();
    for (my $i=0; $i <@Filenames; $i++){
        push @tmpfile, ($Filenames[$i] =~ /$prefix\.([0-9]{8})\.tar/);
    }

    my @Sorted = sort { $b <=> $a } @tmpfile;
    while ($cnt < @Sorted){
        my $doidelete = 1;
        if ($keep < $numofbackups){
            $doidelete = 0;
            $keep++;
        }
        my ($firstomon) = ($Sorted[$cnt] =~ /\d{6}(\d{2})/);
        if ($firstomon =~ /^01$/){
            $doidelete = 0;
        }

        if ($doidelete == 1){
            unlink($destloc . "$prefix." . $Sorted[$cnt] . ".tar.gz");
        }
        $cnt++;
    }
}

sub drop_empty { #Drop 0 length items out of array
    my @out;
    my @in = @_;
    for (my $i = 0; $i < scalar(@in); $i++){
        $in[$i] = trim($in[$i]);
        if (length($in[$i]) >= 1){
            push @out, $in[$i];
        }
    }

    return @out;
}

#trim whitespace
sub trim {
    my @out = @_;
    for (@out){
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @out: $out[0];
}
