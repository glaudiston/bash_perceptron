#!/bin/bash
#
# This is a linear one to one perceptron
# Expect to predict a number, in this case multiply by 3 + 20 (bias)
declare -a inputs=( 1 2 3 4 5 );
declare -a outputs=( 23 26 29 32 35 );
declare b=0;
declare w=0;
declare lr=0.1;
declare epochs=5000;

coproc BC { { echo "scale=8;";cat; } | bc -l; }

calc(){
	echo "$@" >&${BC[1]};
	read V <&${BC[0]};
	echo $V
}

predict(){
	local x=$1;
	local w=$2;
	local b=$3;
	calc "$x * $w + $b";
}

train(){
	declare -a epoch_loss=( );
	declare -a epoch_bias=( );
	w_p=0;
	w_pp=0;
	b_p=0;
	b_pp=0;
	for epoch in $(seq $epochs); do
		declare -a predictions=( );
		declare -a loss=( );
		declare -a sign_loss=( );
		local lr_correction_sum=0;
		local loss_sum=0;
		local sign_loss_sum=0;
		for (( i=0; i<${#inputs[@]}; i++)); do
			predictions[$i]=$(predict "${inputs[$i]}" "$w" "$b");
			loss[$i]=$(calc "${outputs[$i]} - ${predictions[$i]}");
			sign_loss[$i]=$( [ "$(calc "${loss[$i]} < 0")" == "1" ] && echo -1 || echo 1 );
			sign_loss_sum=$(calc "$sign_loss_sum + ${sign_loss[$i]}");
			loss_sum=$(calc "$loss_sum + ${loss[$i]}");
			lr_correction_sum=$(calc "$lr_correction_sum + ${sign_loss[$i]} * ${inputs[$i]}")
		done;
		local loss_avg=$(calc "$loss_sum / ${#inputs[@]}");
		w=$(calc "$w + $lr * $lr_correction_sum");
		b=$(calc "$b + $lr * $sign_loss_sum / ${#inputs[@]}");
		if [ "$(calc "$w == $w_pp")" == "1" -a "$(calc "$b == $b_pp")" == "1" ]; then  # we are in a train lock
			lr=$(calc "$lr / 2"); # learn slower
		else
			echo "not equal: w: $w; w_pp: $w_pp; b=$b; b_p: $b_pp";
		fi;
		w_pp="$w_p";
		b_pp="$b_p";
		w_p="$w"; # previous weight;
		b_p="$b"; # previous bias;
		echo "epoch: $epoch; learning rate=$lr; loss=${loss_avg}; bias=$b; weight=$w; predictions=${predictions[@]};"
		[ "$(calc "$lr == 0")" == 1 ] && break;
	done;
}

predict 10 $w $b
train;
predict 10 $w $b
exit

plot(){
	gnuplot -persist <<EOF
set terminal png
set output "$1.png"
set xzeroaxis
set yzeroaxis
set border 0          # remove frame
set xtics axis        # place tics on axis rather than on border
set ytics axis
set ticscale 0        # [optional] labels only, no tics
set xtics add ("" 0)  # suppress origin label that lies on top of axis
set ytics add ("" 0)  # suppress origin label that lies on top of axis
#
# if arrows are wanted only in the positive direction
set arrow 1 from 0,0 to graph 1, first 0 filled head
set arrow 2 from 0,0 to first 0, graph 1 filled head
#
# if arrows in both directions from the origin are wanted
set arrow 3 from 0,0 to graph 0, first 0 filled head
set arrow 4 from 0,0 to first 0, graph 0 filled head
set datafile separator ","
plot '$1.csv' using 1:2:3:4 with points pt variable ps 1 lc variable title "[$1]"
EOF
}

plot inputs
cat inputs.csv | perceptron > func.csv
plot weights
magick -delay 40 inputs.png weights*.png output.gif
display output.gif
