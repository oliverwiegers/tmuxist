dev:
	cp ../tmux/.tmux.conf ./whole_file
	cut -c3- ./whole_file | sed '0,/^EOF$$/d' > ./custom_functions.sh
	sed '1,/^# EOF$$/!d' ./whole_file > ./tmux.conf

build:
	cat ./tmux.conf > ./whole_file
	sed 's/^/# /g;s/^# $$/#/g;' custom_functions.sh >> ./whole_file

deploy:
	cat ./tmux.conf > ./whole_file
	sed 's/^/# /g;s/^# $$/#/g;' custom_functions.sh >> ./whole_file
	cp ./whole_file ../tmux/.tmux.conf

install: build deploy

cleanup:
	rm ./tmux.conf ./whole_file ./custom_functions.sh
