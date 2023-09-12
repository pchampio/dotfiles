#!/usr/bin/perl

$sq = "squeue -Su -o '\''%15i %10u %20j %4t %5D %20R %15b %3C %7m %11l %11L'\''";
$cmd = "$sq | grep gpu";

$si="sinfo -o '\''%14P %10n %.11T %.4c %.8z %.6m %30G %10l %10L %10O %20E %25f'\'' -S '\''-P'\''";
$sig="$si | grep gpu";

@out = `$cmd`;

%jobs=(); #cle=user, value=nbGpus
%jdetails=(); #cle=node, value=dict()/key=user, value=nb
%igpus=(); #cle=gpu, value=info sig
%ucpus=(); #cle=gpu, value=nbUsed/nbCPU
%umems=();
%gpus=(); #cle=gpu, value=nbUsed
$nbUsed=0;

%file=(); #cle=node, value=partition(s)
%hpj = (); #cle=name, value=nbHPJ

foreach(@out){
	$l=$_;
	chomp($l);
	@nodes = ();
	@infos = split(/\s+/, $l);
	$name = $infos[1];
	$jname = $infos[2];
	$ginfo = $infos[6];
	$ginfo =~ s/\(S:\d+(?:-\d+)?\)//;
	$node = $infos[5];
	if($node =~ /^(.*)\[(.*)\]$/){
		$deb=$1;
		$inside=$2;
		if($inside =~ /\-/){
			@ii = split("-", $inside);
			$from = $ii[0];
			$to = $ii[1];
			@ii = ();
			for($i=$from; $i<=$to; $i++){
				push(@ii, sprintf("%02d", $i));
			}
			@nodes = ();
			foreach(@ii){
				push(@nodes, $deb.$_);
			}
		}elsif($inside =~ /\,/){
			@ii = split(",", $inside);
			@nodes = ();
			foreach(@ii){
				push(@nodes, $deb.$_);
			}
		}


	}else{
		push(@nodes, $node);
	}
	$state = $infos[3];
	$cpus = $infos[7];

	$cpus = sprintf("%d", $cpus/scalar(@nodes));

	$memu = $infos[8];

	next if($l =~ /ReqNodeNotAvail/);

	next if($l =~/launch failed/);

	if($memu =~ /^(.*)M$/){
		$memu=$1;
		$memu = $memu/1000;
	}elsif($memu =~ /^(.*)G/){
		$memu = $1;
	}else{
		die "Strange menu $memu\n";
	}
	next if ($state ne "R");
	$nb=-1;
	if($ginfo =~ /:([0-9]+)$/){
		$nb = $1;
	}else{
		#die "Strange line !! $l\n";
		$nb = 0;
	}

	if($jname =~ /_HP$/){
		if(!exists($hpj{$name})){
			$hpj{$name}=0;
		}
		$hpj{$name}+=$nb;
	}
	$jobs{$name}=0 if(!exists($jobs{$name}));
	foreach(@nodes){
		$node = $_;
		$gpus{$node}=0 if(!exists($gpus{$node}));

		if(!exists($jdetails{$node})){
			my %d=();
			$jdetails{$node}=\%d;
		}
		$d=$jdetails{$node};
		$d->{$name}=0 if(!exists($d->{$name}));
		$d->{$name}+=$nb;
		$jobs{$name}+=$nb;
		$gpus{$node}+=$nb;
		if(!exists($ucpus{$node})){
			$ucpus{$node}=$cpus."/0";
		}else{
			@prev = split("/", $ucpus{$node});
			$ucpus{$node}= ($prev[0]+$cpus)."/0";
		}

		if(!exists($umems{$node})){
			$umems{$node}=$memu."/0";
		}else{
			@prev = split("/", $umems{$node});
			$umems{$node}= ($prev[0]+$memu)."/0";
		}

		$nbUsed+=$nb;
	}

}


$cmd = "$sig | grep gpu";
@out = `$cmd`;
%gpui=(); #cle=gpu, value=nbDispo/type
%memgpu=(); #cle=gpu, value=memgpu

foreach(@out){
	$l=$_;
	chomp($l);
	@infos = split(/\s+/, $l);
	$partition = $infos[0];
	$ginfo = $infos[6];
	$ginfo =~ s/\(S:\d+(?:-\d+)?\)//;
	$node = $infos[1];
	$state = $infos[2];
	$cpus = $infos[3];
	$memu = $infos[5];
	$memg = $infos[scalar(@infos)-1];
	@iinfos = split(/\,/, $memg);
	$memgpu{$node}="";
	for($j=1; $j<scalar(@iinfos); $j++){
		$memgpu{$node}.=$iinfos[$j].",";
	}
	chop($memgpu{$node});
	$memgpu{$node} =~ s/gpu//g;
	if(!exists($file{$node})){
		$file{$node}=$partition;
	}else{
		$file{$node} .= ",".$partition;
	}
	$nb=-1;
	if($ginfo =~ /:([0-9]+)$/){
		if($ginfo =~ /,/){
			@ginfos = split(/\,/, $ginfo);
			$nb=0;
			$type="";
			foreach(@ginfos){
				$ginfo = $_;
				$nbEach=0;
				if($ginfo =~ /:([0-9]+)$/){
					$nb += $1;
					$nbEach = $1;
				}
				@gg = split(/\:/, $ginfo);
				$type .= $gg[1].":".$nbEach.",";
			}
			chop($type);
		}else{
			$nb = $1;
			@gg = split(/\:/, $ginfo);
			$type=$gg[1];
		}
	}else{
		die "Strange line end !! $l\n";
	}
	$gpui{$node}=$nb."/".$type;
	$igpus{$node}=$state;
	if(!exists($ucpus{$node})){
		$ucpus{$node}="0/".$cpus;
	}else{
		@prev = split("/", $ucpus{$node});
		$ucpus{$node}=$prev[0]."/".$cpus;
	}

	$memu = sprintf("%3d", $memu/1000)." G";
	$val = 0;
	if(exists($umems{$node})){
		@prev = split("/", $umems{$node});
		$val = $prev[0];
	}
	$val = sprintf("%3d", $val);

        $umems{$node}=$val."/".$memu;


}
$tot = 0;
foreach(keys %gpui){
	$node=$_;
	@i=split("/",$gpui{$node});
	$tot += $i[0];
}
$lenNb=10;

afficheDetails();
print "\n\n\n";
afficheRes();

print "\n";
print "TOTAL = ".$nbUsed." / ".$tot." GPU USED\n";


sub afficheRes{
	$maxLen=15;
	$lenNb = 10;

	$nSep = $maxLen+$lenNb+$lenNb+2;

	print "+";
	print printNsep($nSep, "-");
	print "+\n";
	print "|";
	print printNCars($maxLen, "Users");
	print "|";
	print printNCars($lenNb, "#GPU");
	print "|";
	print printNCars($lenNb, "#HPJ");
	print "|\n";

	printSepL();



	foreach(sort sortRes keys %jobs){
		$name = $_;
		print "|";
		print printNCars($maxLen, " ".$name, "l");
		print "|";
		print printNCars($lenNb, $jobs{$name});
		print "|";
		if (exists($hpj{$name})){
			$nbHP = $hpj{$name};
			if($nbHP > 2){
				$nbHP .= " /!\\ ";
			}
			print printNCars($lenNb, $nbHP);
		}else{
			print printNCars($lenNb, 0);
		}
		print "|\n";
	}

	print "+";
	print printNsep($nSep, "-");
	print "+\n";
}


sub afficheDetails{
	$nodeLen=10;
	$typeLen=10;
	$lenDetails=10;
	$lenPart=10;
	$lenNb=10;


	for(keys %gpui){
		$node=$_;
		$max = length($file{$node})+2;
		$lenPart = $max if($max > $lenPart);
		$details = "";
		if(exists($jdetails{$node})){
			$d = $jdetails{$node};
			foreach(keys %$d){
				$user=$_;
				$details.=$user.":".$d->{$user}." ";
			}
		}
		$max = length($details)+2;
		$lenDetails = $max if($max > $lenDetails);
		$type = $gpui{$node};
		@ii = split(/\//, $type);
		$max = length($ii[1])+2+length($memgpu{$node})+1;
		$typeLen = $max if($max > $typeLen);
	}

	$nSep = $nodeLen+$lenNb+$lenNb+$typeLen+$lenDetails+$lenNb+$lenNb+$lenNb+$lenPart+8;
	print "+";
	print printNsep($nSep,"-");
	print "+\n";
	print "|";
	print printNCars($nodeLen, "Nodes");
	print "|";
	print printNCars($lenPart, "Partition");
	print "|";
	print printNCars($lenNb, "#GPU");
	print "|";
	print printNCars($lenNb, "#Used");
	print "|";
	print printNCars($lenNb, "#Free");
	print "|";
	print printNCars($lenDetails, "Details");
	print "|";
	print printNCars($typeLen, "Type");
	print "|";
	print printNCars($lenNb, "#CPU");
	print "|";
	print printNCars($lenNb, "#Mem");
	print "|\n";

	printSepL();

	for(sort keys %gpui){
		$node = $_;
		$details="";
		if(exists($jdetails{$node})){
			$d = $jdetails{$node};
			foreach(keys %$d){
				$user=$_;
				$details.=$user.":".$d->{$user}." ";
			}
		}
		print "|";

		print printNCars($nodeLen, $node);
		print "|";

		print printNCars($lenPart, $file{$node});
		print "|";

		$infos = $gpui{$node};
		@ii = split(/\//, $infos);
		$nbG=$ii[0];

		print printNCars($lenNb, $nbG);
		print "|";
		$nbU = 0;
		$nbU = $gpus{$node} if(exists($gpus{$node}));

		print printNCars($lenNb, $nbU);
		print "|";

		$free=$nbG-$nbU;
		print printNCars($lenNb, $free);
		print "|";

		print printNCars($lenDetails, $details);
		print "|";

		#
		$memGP = $memgpu{$node};
		$cardName = $ii[1];
		@iCard = split(/\,/, $cardName);
		@iMem = split(/\,/, $memGP);
		$ch = $ii[1].":".$memgpu{$node};
		if(scalar(@iCard) == scalar(@iMem)){
			$ch = "";
			for($j=0; $j<scalar(@iCard);$j++){
				$ch .= $iCard[$j].":".$iMem[$j].",";
			}
			chop($ch);
		}

		print printNCars($typeLen, $ch);
		print "|";

		print printNCars($lenNb, $ucpus{$node});
		print "|";

		print printNCars($lenNb, $umems{$node});
		print "|";

		if($igpus{$node} !~ /mixed/){
			print " <- $igpus{$node}";
		}
		print "\n";
	}

	print "+";
	print printNsep($nSep, "-");
	print "+\n";
}




sub sortRes{
        return $jobs{$b} <=> $jobs{$a};
}

sub printNsep{
        my $n = $_[0];
        my $sep = $_[1];
        my $i;
        my $chaine="";
        for($i=0;$i<$n;$i++){
                $chaine .= $sep;
        }
        return $chaine;
}

sub printNCars{
        my $n = $_[0];
        my $mot = $_[1];
        my $align = $_[2];
        my $diff = $n-length($mot);
        my $chaine="";
        my $i;
        if($align eq "" || $align eq "c"){
                my $bef = int($diff/2);
                my $aff = $diff-$bef;
                for($i=0; $i<$bef; $i++){
                        $chaine .= " ";
                }
                $chaine .= $mot;
                for($i=0; $i<$aff; $i++){
                        $chaine .= " ";
                }
        }elsif($align eq "l"){
                my $aff = $diff;
                $chaine=$mot;
                for($i=0; $i<$aff; $i++){
                        $chaine .= " ";
                }
        }elsif($align eq "r"){
                my $bef = $diff;
                $chaine="";
                for($i=0; $i<$bef; $i++){
                        $chaine .= " ";
                }
                $chaine .= $mot;
        }
        return $chaine;
}

sub printSepL{
        print "|";
        print printNsep($nSep, "-");
        print "|\n";
}
