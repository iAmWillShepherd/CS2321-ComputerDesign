#! /usr/bin/perl -w

use strict;
use warnings;
#################################################
#Assembly Simulation							#
#by, William R. Shepherd						#
#CSCI 2321 										#
#Computer Design - Dr. Eggen					#
#################################################
use constant NULL    => -1;
use constant EXECUTE => 0;

#Insctruction Set
use constant LW	     => "100011";
use constant SW		 => "101011";
use constant AND	 => "100100";
use constant ADD	 => "100000";
use constant SUB     => "100010";
use constant BEQ     => "000100";
use constant ADDI	 => "001000";
use constant J		 => "000010";
use constant OR		 => "100101";

#Global Variables
my @register = (0 .. 32);
my @instructionMem = (0 .. 1024);
my @dataMem = (0..64);
my $PC = 0;
my @token = NULL;
my $iReg;

#Instruction Variables
my $InstructionType = NULL;
my $opcode = NULL;
my $rs = NULL;
my $rt = NULL;
my $rd = NULL;
my $shamt = NULL;
my $funct = NULL;
my $immediate = NULL;

#Control Variables
my $RegDst   = NULL;
my $Jump  	 = NULL;
my $Branch 	 = NULL;
my $MemRead  = NULL;
my $MemToReg = NULL;
my $ALUOP 	 = NULL;
my $MemWrite = NULL;
my $ALUSrc 	 = NULL;
my $RegWrite = NULL;

#Initialization
system("clear");

foreach $iReg (@register) {$register[$iReg] = 0};
foreach $iReg (@instructionMem) {$instructionMem[$iReg] = 0};
foreach $iReg (@dataMem) {$dataMem[$iReg] = 0};

my $dataFile = "junk.txt";
open(HANDLE, $dataFile) || die("Could not open file!");
my @raw_data = <HANDLE>;
close(HANDLE);

my $Line_Var = 0;
my $iter = 0;

foreach $Line_Var (@raw_data)
{
	chomp($Line_Var);
	$instructionMem[$iter] = $Line_Var; 
	$iter++;
#	print "$instructionMem[$iter]\n";
}

#print "$instructionMem[0]\n";
#print "$instructionMem[1]\n";

RUN_INTERFACE();

#################################################
#This subroutine shall be responsible for 		#
#recieving user input and sending all relevant	#
#to the PARSER.									#
#'EXIT' exits the subroutine back into main		#
#program										#
#################################################
sub RUN_INTERFACE
{
	my $input = "";
	my $stop = $iter;
	$iter = 0;
	
	
	#while($input ne "!")
	while($iter != $stop)
	{
		print "-> ";
		
		#$input = <STDIN>;
		$input = $instructionMem[$iter];
		chomp($input);
		
		if($input ne "x")
		{
			if(RUN($input) == 1)
			{
				$PC = $PC + 4;
			#	$PC = $iter;
				
				print "-> Argument Accepted!\n";
			}
			else	
			{
				print "-> Argument Rejected!\n";
			}
		}
		else 
		{
			$input = "!";
		}
		
		$iter++;
		
		my $wait = <stdin>;
	}
}

#################################################
#The 'RUN' subroutine shall be responsible for 	#
#finding Reserved words in the argv array. If	#
#no reservened word exists, 'RUN' shall exit    #
#and return EXECUTE -> -1						#
#################################################
sub RUN
{
	my $Input  = $_[0];
	
#	print "-> Subroutine 'RUN' : Input $Input\n";
	$instructionMem[$PC] = $Input;
	print "-> $Input loaded into instruction Memory at location $iter\n";

	Tokenize($Input);
	
	DispReg();

	return EXECUTE + 1;
}

#################################################
#The 'DispReg' subroutine shall be responsible	#
#for displaying the values in each of the 32	#
#registers used by the assembler				#
#################################################
sub DispReg 
{
	my $i; 
	my $j;
	my $reg = "";
	
	printf "-> PC:= %08d\n", $PC;
	print "-> ----------------------------------------------------------------------------------------------------------------------------\n";
	
	print "-> RegDst: \t$RegDst\n-> Jump: \t$Jump\n-> Branch: \t$Branch\n-> MemRead: \t$MemRead\n-> MemToReg: \t$MemToReg\n-> ALUOp: \t$ALUOP\n-> MemWrite: \t$MemWrite\n-> ALUSrc: \t$ALUSrc\n-> RegWrite: \t$RegWrite\n";
	print "-> ----------------------------------------------------------------------------------------------------------------------------\n";
	
	for ($j = 0; $j < 8; $j++)
	{
		for ($i = 0; $i < 32; $i++)
		{
			if(($i % 8) == $j)
			{
				$reg = whichRegister($i);

				if($i < 8)
				{
					printf("-> \tR%02d ($reg) = %08b\t" , $i, $register[$i]);
				}
				else
				{
					printf("\tR%02d ($reg) = %08b\t", $i, $register[$i]);
				}
			}
		}
		
		print "\n";
	}
	print "------------------------------------------------------------------------------------------------------------------------------\n";
	return 0;
}

#################################################
#The 'whichRegister' subroutine takes a decimal	#
#number as input and returns the register name	#
#################################################
sub whichRegister
{
	my $reg = "";
	my $i = $_[0];

	if($i == 0)     {$reg = "r0";}              #Register 0
    elsif($i == 1)  {$reg = "at";}              #Register at
    elsif($i < 4)   {$reg = "v" . ($i - 2);}    #Register v0-v1
    elsif($i < 8)   {$reg = "a" . ($i - 4);}    #Register a0-a3
    elsif($i < 16)  {$reg = "t" . ($i - 8);}    #Register t0-t7
    elsif($i < 24)  {$reg = "s" . ($i - 16);}   #Register s0-s7
    elsif($i < 26)  {$reg = "t" . ($i - 16);}   #Register t8-t9
    elsif($i < 28)  {$reg = "k" . ($i - 26);}   #Register k0-k1
    elsif($i == 28) {$reg = "gp";}              #Register gp
    elsif($i == 29) {$reg = "sp";}              #Register sp
    elsif($i == 30) {$reg = "s8";}              #Register s8
    else{$reg = "ra";}                          #Register ra

	return $reg;
}

#################################################
#The "TOKENIZE' sub routine exist only to		#
#prepare a string for parsing by seperating		#
#input into substrings							#
#################################################
sub Tokenize
{
	my $input = $_[0];

	if ((substr($input, 0, 1) eq "0") || (substr($input, 0, 1) eq "1"))
	{
	#	print "-> Sending to Parser\n";
		ParseInst($input);
	}
	else
	{
	#	print "-> Tokenizing string\n";
		@token = split(/ /, $_[0]);
		return EXECUTE + 1;
	}
}

#################################################
#Takes an instruction in Binary format and		#
#and parses the instruction for use by the ALU	#
#################################################
sub ParseInst
{
	my $input = $_[0];

	if(substr($input, 0, 6) eq "000000")
	{
		$InstructionType = 0;
		print "-> Recieved R-Type Instruction\n";
		print "------------------------------------------------------------------------------------------------------------------------------\n";
	}
	else
	{
		$InstructionType = 1;
		print "-> Recieved I-Type Instuction\n";
		print "------------------------------------------------------------------------------------------------------------------------------\n";	
	}

	if($InstructionType == 0)
	{
		$opcode = substr($input, 0, 6);
		$rs = substr($input, 6, 5); 
		$rt = substr($input, 11, 5);

		$rd = substr($input, 16, 5);
		$shamt = substr($input, 21, 5);
		$funct = substr($input, 26, 6);
		
		my $instruction = whichInstruction();
		
		print "-> Opcode: (6 bits) $opcode\n";
		print "-> rs    : (5 bits) $rs\n";
		print "-> rt    : (5 bits) $rt\n";
		print "-> rd    : (5 bits) $rd\n";
		print "-> shamt : (5 bits) $shamt\n";
		print "-> funct : (6 bits) $funct\n";
		
		print "-> $instruction \$", whichRegister(bin2dec($rd)), ", \$", whichRegister(bin2dec($rs)), ", \$", whichRegister(bin2dec($rt)), "\n";
		
		#print "@register[bin2dec($rs)]\n";
			
	}
	else
	{
		$opcode = substr($input, 0, 6);
		$rs = substr($input, 6, 5); 
		$rt = substr($input, 11, 5);
		$immediate = substr($input, 16, 16);

		my $instruction = whichInstruction();

		print "-> Opcode: (6 bits)  $opcode\n";
		print "-> rs    : (5 bits)  $rs\n";
		print "-> rt    : (5 bits)  $rt\n";
		print "-> imm   : (16 bits) $immediate\n";
		
		print "-> $instruction \$", whichRegister(bin2dec($rt)), " \$", whichRegister(bin2dec($rs)), "(", bin2dec($immediate), ")\n";
	}

	return EXECUTE + 1;

}

#Also the ALU
sub whichInstruction
{	
#	print "-> Running whichInstruction\n";
	
	if ($InstructionType == 0)
	{
		#Set Flags
		$RegDst = 1; $Jump = 0; $Branch = 0; $MemRead = 1; $MemToReg = 0; $ALUOP = dec2bin(2); $MemWrite = 1; $ALUSrc = dec2bin(2); $RegWrite = 0;
		
		if ($funct eq ADD)
		{	
			$register[bin2dec($rd)] = Add($register[bin2dec($rs)], dec2bin($register[bin2dec($rt)]));
			return "add";
		}
		elsif ($funct eq AND)
		{
			$register[bin2dec($rd)] = And($register[bin2dec($rs)], $register[bin2dec($rt)]);
			return "and";
		}
		elsif ($funct eq OR)
		{
			$register[bin2dec($rd)] = Or($register[bin2dec($rs)], $register[bin2dec($rt)]);
			return "or";
		}
		elsif ($funct eq SUB)
		{
			$register[bin2dec($rd)] = Subtract($register[bin2dec($rs)], $register[bin2dec($rt)]);
			return "sub";
		}
		else
		{
			return "FAIL R-Type";
		}
	}
	else
	{	
		if ($opcode eq LW)
		{
			$RegDst = 0; $Jump = 0; $Branch = 0; $MemRead = 1; $MemToReg = 1; $ALUOP = dec2bin(0); $MemWrite = 0; $ALUSrc = dec2bin(1); $RegWrite = 1;
			Lw();
			return "lw";
		}
		elsif ($opcode eq SW)
		{
			$RegDst = 0; $Jump = 0; $Branch = 0; $MemRead = 0; $MemToReg = 0; $ALUOP = dec2bin(0); $MemWrite = 1; $ALUSrc = dec2bin(1); $RegWrite = 0;
			Sw();
			return "sw";
		}
		elsif ($opcode eq BEQ)
		{
			$RegDst = 0; $Jump = 0; $Branch = 1; $MemRead = 0; $MemToReg = 0; $ALUOP = dec2bin(0); $MemWrite = 0; $ALUSrc = dec2bin(0); $RegWrite = 0;
			Beq();
			return "beq";
		}
		elsif ($opcode eq ADDI)
		{	
			$RegDst = 0; $Jump = 0; $Branch = 0; $MemRead = 0; $MemToReg = 0; $ALUOP = dec2bin(0); $MemWrite = 0; $ALUSrc = dec2bin(1); $RegWrite = 1;
			$register[bin2dec($rt)] = bin2dec(Add($register[bin2dec($rs)], $immediate));
			return "addi";
		}
		elsif ($opcode eq J)
		{
			$RegDst = 0; $Jump = 1; $Branch = 0; $MemRead = 0; $MemToReg = 0; $ALUOP = dec2bin(0); $MemWrite = 0; $ALUSrc = dec2bin(0); $RegWrite = 0;
			Jump();
			return "jump";
		}
		else
		{
			return "FAIL I-Type\n";
		}
	}
}

#################################################
#Utilities - Just random functions that are     #
#useful for having								#
#################################################
sub dec2bin 
{
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}

#sub dec2bin
#{
#	my $input = $_[0];
#  	$ps = pack( 's', $input );
#	return $ps;
#}

sub bin2dec 
{
    return unpack("N", pack("B32", substr("L" x 32 . shift, -32)));
}

#sub bin2dec
#{
#	my $input = $_[0];
#	my $s  = unpack( 's', $ps );
#	return $s;
#}

sub signExtend
{
	my $input = $_[0];
	my $extendBy = 0;
	my $strLength = length($input);
	
	if ((substr($input, 0, 1) eq 1) && (length($input) eq 16))
	{
		while ($strLength < 32)
		{
			$input = "1$input";
	    	$strLength = length($input);
		}
	}
	else
	{	
		while ($strLength < 32)
		{
			$input = "0$input";
		   	$strLength = length($input);
		}
	}
	
	return $input
}

sub COMPLEMENT
{
	my $a = $_[0];
	my $temp = "";
	my $result = 0;
	
	print "a: $a length:= ", length($a), "\n";
	
	for (my $i = 0; $i < 32; $i++)
	{
		$result = INVERT(substr($a, 31 - $i, 1));
		$temp = "$result$temp";
	}
	
#	print "temp:= $temp Length ", length($temp), "\n";
	$result = Add($temp, signExtend("1"));
	
	return $result;
}

sub shiftBy2
{
	my $a = $_[0];
	my $result = $a << 2;
	
	return $result;
}

#################################################
#Logical Operator								#
#################################################
sub AND_Gate
{
	my $a = $_[0];
	my $b = $_[1];#
	my $c = NULL;

	if ($a && $b) {$c = 1;} else {$c = 0;}

#	print "-> Subroutine 'AND_Gate' : Input $a, $b : Return $c\n";
	
	return $c;
}

sub OR_Gate
{
	my $a = $_[0];
	my $b = $_[1];
	my $c = NULL;

	if ($a || $b) {$c = 1;} else {$c = 0;}

#	print "-> Subroutine 'OR_Gate' : Input $a, $b : Return $c\n";

	return $c;
}

sub INVERT
{
	my $a = $_[0];
	my $b = NULL;
	my $c = NULL;

	if ($a == 0) {$c = 1;} else {$c = 0;}

#	print "-> Subroutine 'INVERT' : Input $a : Return $c\n";

	return $c;
}

sub MULTIPLEX
{
	my $a = $_[0];
	my $b = $_[1];
	my $d = $_[2];
	my $c = NULL;

	if ($d == 0) {$c = $a;} else {$c = $b;}

#	print "-> Subroutine 'MULTIPLEX' : Input $a, $b, $d : Return $c\n";

	return $c;
}

sub ONE_BIT_ADDER
{
	#Inputs 
	my $a  = $_[0];
	my $b  = $_[1];
	my $ci = $_[2];

	#Outputs
	my $co  = NULL;
	my $sum = NULL;

	if (($a && $ci) || ($b && $ci) || ($a && $b)) {$co = 1;} 
	else {$co = 0;}
	if ((!$a && !$b && $ci) || (!$a && $b && !$ci) || ($a && !$b && !$ci) || ($a && $b && $ci)) {$sum = 1;} 
	else {$sum = 0;}

#	print "-> Subroutine 'ONE_BIT_ADDER' : Input a: $a, b: $b, ci: $ci : Return co: $co, sum: $sum\n";

	return ($co, $sum);
}

#Instructions
sub Or
{
	my $a = $_[0];
	my $b = $_[1];
	my $result = 0;
	my $temp = "";
	
	$a = signExtend($a);
	$b = signExtend($b);
	
	print "a: $a, ", bin2dec($a), "\n";
	print "b: $b, ", bin2dec($b), "\n";
	
	for (my $i = 0; $i < 32; $i++)
	{
		$result = OR_Gate(substr($a, 31 - $i, 1), substr($b, 31 - $i, 1));
		$temp = "$result$temp";
	}
	
	return $temp;
}

sub Add
{
	my $a = $_[0];
	my $b = $_[1];
	my $Sum = 0;
	my $temp = "";
	my $ci = 0;
	my @arr;
	
	$a = signExtend($a);
	$b = signExtend($b);
	
	print "-> Adding A to B\n";
	print "-> a: $a length:= ", length("$a"), "\n";
	print "-> b: $b length:= ", length("$b"), "\n";
	
	for (my $i = 0; $i < 32; $i++)
	{
		(@arr) = &ONE_BIT_ADDER(substr($a, 31 - $i, 1), substr($b, 31 - $i, 1), $ci);
		$ci = $arr[0];
		$Sum = $arr[1];
		$temp = "$Sum$temp";
	}
	
	
	print "$temp\n";
	
	return $temp;
}

sub Subtract
{
	my $a = $_[0];
	my $b = $_[1];
	my $result = 0;
	
	$a = signExtend($a);
	$b = signExtend($b);

	print "a: $a length:= ", length("$a"), "\n";
	print "b: $b length:= ", length("$b"), "\n";
	
	$result = Add($a, COMPLEMENT($b));
	
	return $result;
}

sub And
{
	my $a = $_[0];
	my $b = $_[1];
	my $result = 0;
	my $temp = "";
	
	$a = signExtend($a);
	$b = signExtend($b);
	
	print "a: $a length:= ", length("$a"), "\n";
	print "b: $b length:= ", length("$b"), "\n";
	
	for (my $i = 0; $i < 32; $i++)
	{
		$result = AND_Gate(substr($a, 31 - $i, 1), substr($b, 31 - $i, 1));
		$temp = "$result$temp";
	}
	
	return $temp;
}

sub Lw
{
	$register[$rt] = $dataMem[$immediate];
}

sub Sw
{
	$dataMem[$immediate] = $register[$rt]; 
}

sub Beq
{
	if($register[bin2dec($rs)] == $register[bin2dec($rt)])
	{
		$iter = $iter + $immediate;
	}
	else
	{
		print "-> Branch is not equal\n";
	}
}

sub Jump
{
	my $jumpTo = "$rs$rt$immediate";
	$jumpTo = bin2dec($jumpTo);
  	$iter = $jumpTo - 1; 
}



