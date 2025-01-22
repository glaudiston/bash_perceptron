#!/bin/bash
#
# This is a linear one to one perceptron
# Expect to predict a number, in this case multiply by 3
declare -a inputs=( 1 2 3 4 5 );
declare -a outputs=( 3 6 9 12 15 );
declare b=0;
declare w=0.1;
declare lr=0.1;
declare epochs=50;

predict(){
	local x=$1;
	local w=$2;
	local b=$3;
	echo "scale=8; $x * $w + $b" | bc;
}

train(){
	for epoch in $(seq $epochs); do
		declare -a predictions=( );
		declare -a loss=( );
		for (( i=0; i<${#inputs[@]}; i++)); do
			predictions[$i]=$(predict "${inputs[$i]}" "$w" "$b");
			loss[$i]=$(echo "scale=8; ${outputs[$i]} - ${predictions[$i]}" | bc);
		done;
		w=$(echo "scale=8; $w + $lr * $loss" | bc)
		echo "epoch: $epoch; predictions=${predictions[@]}; loss=${loss[@]}"
	done;
}
predict 10 $w $b
train >/dev/null;
predict 10 $w $b
exit
activation(){
	[ $1 -gt 0 ];
}

predict(){
	v=$1;
	w=$2;
	echo $(( v * w ));
}

perceptron(){
	local inputs;
	local weights;
	touch weights.csv
	exec 3<weights.csv
	while read inputs;
	do
		# step 1: calculate the dot product of the inputs over the weights
		read weights <&3;
		inputs_count=$(echo $inputs | tr , '\n' | wc -l);
		inputs_count=$((inputs_count-2)); # ignore the last 2 columns as they are point type and color
		inp_type=$(echo $input | cut -d, -f3)
		sum=0;
		for (( i=1; i<=inputs_count; i++ )); # cut fields starts with 1
		do
			inp=$(echo $inputs | cut -d, -f$i)
			w=$(echo $weights | cut -d, -f$i)
			p=$(predict $inp $w);
			w=${w:=1};
			n="0.2"; #learning rate
			d=1; #type classification value;
			[ "$inp_type" == "25" ] && d=-1;
			w=$(echo "scale=8; $w + $n * $d * $inp " | bc);
			echo -n $w,
			sum=$(echo "scale=8; $sum + $w" | bc);
		done;
		echo $(echo $inputs | tr , "\n" | sed -e "/^$/d" | tail -2 | tr "\n" ,);
	done;
}

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

generate_data(){
	local data_file=$1;
	echo -n > inputs.csv;
	echo -n > outputs.csv;
	for (( i=1; i<6; i++ )){
		tp=22; #$(( RANDOM % 2 ? 22 : 25))
		c=100;
		#[ $tp == 22 ] && c=150;
		#echo "$(( RANDOM % 256 - 127 )),$(( RANDOM % 256 - 127)),$tp,$c" >> $data_file;
		echo $i,$i,$tp,$c >> inputs.csv;
		echo $i,$(( i * 3 )),$tp,$c >> outputs.csv;
	}
}

generate_data;
plot inputs
cat inputs.csv | perceptron > func.csv
plot weights
magick -delay 40 inputs.png weights*.png output.gif
display output.gif
