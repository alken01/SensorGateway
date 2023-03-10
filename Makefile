TITLE_COLOR = \033[33m
NO_COLOR = \033[0m
TIMEOUT = 4
# when executing make, compile all exe's
all: sensor_gateway sensor_node file_creator

# When trying to compile one of the executables, first look for its .c files
# Then check if the libraries are in the lib folder
sensor_gateway : main.c connmgr.c datamgr.c sensor_db.c sbuffer.c lib/libdplist.so lib/libtcpsock.so
	@echo "$(TITLE_COLOR)\n***** CPPCHECK *****$(NO_COLOR)"
	cppcheck --enable=all --suppress=missingIncludeSystem main.c connmgr.c datamgr.c sensor_db.c sbuffer.c
	@echo "$(TITLE_COLOR)\n***** COMPILING sensor_gateway *****$(NO_COLOR)"
	gcc -c main.c      -Wall -std=c11 -Werror -DSET_MIN_TEMP=10 -DSET_MAX_TEMP=20 -DTIMEOUT=$(TIMEOUT) -o main.o      -fdiagnostics-color=auto -DDEBUG
	gcc -c connmgr.c   -Wall -std=c11 -Werror -DSET_MIN_TEMP=10 -DSET_MAX_TEMP=20 -DTIMEOUT=$(TIMEOUT) -o connmgr.o   -fdiagnostics-color=auto -DDEBUG
	gcc -c datamgr.c   -Wall -std=c11 -Werror -DSET_MIN_TEMP=10 -DSET_MAX_TEMP=20 -DTIMEOUT=$(TIMEOUT) -o datamgr.o   -fdiagnostics-color=auto -DDEBUG
	gcc -c sensor_db.c -Wall -std=c11 -Werror -DSET_MIN_TEMP=10 -DSET_MAX_TEMP=20 -DTIMEOUT=$(TIMEOUT) -o sensor_db.o -fdiagnostics-color=auto -DDEBUG
	gcc -c sbuffer.c   -Wall -std=c11 -Werror -DSET_MIN_TEMP=10 -DSET_MAX_TEMP=20 -DTIMEOUT=$(TIMEOUT) -o sbuffer.o   -fdiagnostics-color=auto -DDEBUG
	@echo "$(TITLE_COLOR)\n***** LINKING sensor_gateway *****$(NO_COLOR)"
	gcc main.o connmgr.o datamgr.o sensor_db.o sbuffer.o -ldplist -ltcpsock -lpthread -o sensor_gateway -Wall -L./lib -Wl,-rpath,./lib -lsqlite3 -fdiagnostics-color=auto

file_creator : file_creator.c
	@echo "$(TITLE_COLOR)\n***** COMPILE & LINKING file_creator *****$(NO_COLOR)"
	gcc file_creator.c -o file_creator -Wall -fdiagnostics-color=auto

sensor_node : sensor_node.c lib/libtcpsock.so
	@echo "$(TITLE_COLOR)\n***** COMPILING sensor_node *****$(NO_COLOR)"
	gcc -c sensor_node.c -DLOOPS=2 -Wall -std=c11 -Werror -o sensor_node.o -fdiagnostics-color=auto
	@echo "$(TITLE_COLOR)\n***** LINKING sensor_node *****$(NO_COLOR)"
	gcc sensor_node.o -ltcpsock -o sensor_node -Wall -L./lib -Wl,-rpath,./lib -fdiagnostics-color=auto

# If you only want to compile one of the libs, this target will match (e.g. make liblist)
libdplist : lib/libdplist.so
libtcpsock : lib/libtcpsock.so

lib/libdplist.so : lib/dplist.c
	@echo "$(TITLE_COLOR)\n***** COMPILING LIB dplist *****$(NO_COLOR)"
	gcc -c lib/dplist.c -Wall -std=c11 -Werror -fPIC -o lib/dplist.o -fdiagnostics-color=auto
	@echo "$(TITLE_COLOR)\n***** LINKING LIB dplist< *****$(NO_COLOR)"
	gcc lib/dplist.o -o lib/libdplist.so -Wall -shared -lm -fdiagnostics-color=auto

lib/libtcpsock.so : lib/tcpsock.c
	@echo "$(TITLE_COLOR)\n***** COMPILING LIB tcpsock *****$(NO_COLOR)"
	gcc -c lib/tcpsock.c -Wall -std=c11 -Werror -fPIC -o lib/tcpsock.o -fdiagnostics-color=auto
	@echo "$(TITLE_COLOR)\n***** LINKING LIB tcpsock *****$(NO_COLOR)"
	gcc lib/tcpsock.o -o lib/libtcpsock.so -Wall -shared -lm -fdiagnostics-color=auto

# do not look for files called clean, clean-all or this will be always a target
.PHONY : clean clean-all run zip

clean:
	rm -rf *.o sensor_gateway sensor_node file_creator *~ lib/*.o *.db *.FIFO gateway.log *.zip sensor_data_recv *.db*

clean-all: clean
	rm -rf lib/*.so

run : sensor_gateway sensor_node
	valgrind --leak-check=full -s --show-leak-kinds=all --track-origins=yes --leak-check-heuristics=all ./sensor_gateway 3756
#	./sensor_gateway 3756

node : sensor_node 
	valgrind --leak-check=full -s --show-leak-kinds=all --track-origins=yes --leak-check-heuristics=all ./sensor_node 15 3 127.0.0.1 3756 

node2 : sensor_node 
	./sensor_node 21 3 127.0.0.1 3756 

node3 : sensor_node 
	./sensor_node 37 3 127.0.0.1 3756 

zip:
	zip lab_final.zip main.c connmgr.c connmgr.h datamgr.c datamgr.h sbuffer.c sbuffer.h sensor_db.c sensor_db.h config.h lib/dplist.c lib/dplist.h lib/tcpsock.c lib/tcpsock.h