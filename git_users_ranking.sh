#!/bin/bash

# change those vars :
GITHUB_ORG=
GITHUB_ACCESS_TOKEN=
OUTPUT_FILE_PERSONAL=repo_list_personal.json
OUTPUT_FILE_PUBLIC=repo_list_public.json
TMP_FILE=tmpfile.txt
PER_PAGE=100
function list_personal_repos() {
	loop=0
	index=1
	rm -f $TMP_FILE
	echo "[]" > $OUTPUT_FILE_PERSONAL

	while [ "$loop" -ne 1 ]
	do

	    data=`curl -s "https://api.github.com/orgs/$GITHUB_ORG/repos?access_token=$GITHUB_ACCESS_TOKEN&page=$index&per_page=$PER_PAGE"`

	    check_error=`echo "$data"  | jq 'type!="array"'`

	    if [ "$check_error" == "true" ]; then
	        echo "access token is invalid"
	    exit 1
	    fi

	    filtered=`echo "$data" | jq '[ .[] | select(.private == true) ]'`

	    if [ "$filtered" == "[]" ]; then
	        loop=1
	    else
	        echo "$filtered" > $TMP_FILE
	        concat=`jq -s add $TMP_FILE $OUTPUT_FILE_PERSONAL`
	        echo "$concat" > $OUTPUT_FILE_PERSONAL
	        size=`jq '. | length' $OUTPUT_FILE_PERSONAL`
	        echo "computed $index page - fetched total repo size of : $size"
	        index=$((index+1))
	    fi
	done
}

function list_public_repos() {
	loop=0
	index=1
	rm -f $TMP_FILE
	echo "[]" > $OUTPUT_FILE_PUBLIC

	while [ "$loop" -ne 1 ]
	do
	    data=`curl -s "https://api.github.com/orgs/$GITHUB_ORG/repos?page=$index&per_page=$PER_PAGE"`

	    check_error=`echo "$data"  | jq 'type!="array"'`

	    if [ "$check_error" == "true" ]; then
	        echo "access token is invalid"
	    exit 1
	    fi

	    filtered=`echo "$data" | jq '[ .[] | select(.private == false) ]'`

	    if [ "$filtered" == "[]" ]; then
	        loop=1
	    else
	        echo "$filtered" > $TMP_FILE
	        concat=`jq -s add $TMP_FILE $OUTPUT_FILE_PUBLIC`
	        echo "$concat" > $OUTPUT_FILE_PUBLIC
	        size=`jq '. | length' $OUTPUT_FILE_PUBLIC`
	        echo "computed $index page - fetched total repo size of : $size"
	        index=$((index+1))
	    fi
	done

}

function extract_repos_name(){
	ls *repo_list*|xargs -I {} bash -c "grep "full_name" {} |cut -d/ -f2|cut -d'\"' -f1 >>repos_names"
}

function download_bare_info(){
	mkdir repos
	(cd repos
	cat repos_names|xargs -I {} -n1 -P10 bash -c "git clone --bare git@github.com:Telefonica/{}"
	)
}

function extract_number_of_commits() {
	rm people commits_for_each_person
	(cd repos
		echo "Estract commits using shortlog"
		ls|grep git|xargs -I {} -n1 -P10 bash -c 'cd {};git shortlog -s -n --all >>../commits_for_each_person'
		echo "Formatting commits file"
		cat commits_for_each_person |sed 's/^ *//'|sed 's/\t/|/'>tmp;mv tmp commits_for_each_person
		echo "Create file people with uniq names"
		cut -d'|' -f2 commits_for_each_person |sort|uniq>../people
		mv commits_for_each_person ..
		)

}

function create_ranking() {
	rm commits_ordered
	echo "add all values with the same name"

	j=1
	while read name;do
		echo "Extracting user $j with name $name"
		n=$(grep "$name" commits_for_each_person|cut -d'|' -f1|awk '{ sum += $1; } END { print sum; }' "$@")
		echo "$n|$name">>commits_ordered
		let "j++"
	done<"people"
	sort commits_ordered>tmp;mv tmp commits_ordered
	#cat people|xargs -I VAR -n1 echo "`awk -F '|' '$2 ~ /VAR/ {sum += $1} END {print sum}' commits_for_each_person`|VAR">>commits_ordered)
	
}


#list_personal_repos
#list_public_repos
#extract_repos_name
#download_bare_info
#extract_number_of_commits
create_ranking

#listar numero de comandos
#git shortlog -s -n --all --no-merges
