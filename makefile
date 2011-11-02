PLATFORM = $(shell uname)
JARNAME = zmq-2.1.10.jar
JNIBASENAME = libjzmq
ifeq ($(PLATFORM),Darwin)
	JNILIBNAME = $(JNIBASENAME).jnilib
endif
ifeq ($(PLATFORM),Linux)
	JNILIBNAME = $(JNIBASENAME).so
endif

.PHONEY: all clean

OBJS += \
builds/obj/Context.o \
builds/obj/Poller.o \
builds/obj/Socket.o \
builds/obj/util.o \
builds/obj/ZMQ.o

USER_OBJS := /usr/local/lib/libzmq.a

RM := rm -rf

# All Target
all: $(JARNAME) $(JNILIBNAME)

$(JARNAME): src/org/zeromq/*.java
	@echo 'Building JZMQ Jarfile'
	javac src/org/zeromq/*.java
	cd src && jar cf ../$(JARNAME) org/zeromq/*.class org/zeromq/*.java
	@echo ' '

builds/jnih/%.h: $(JAVA_SRCS) $(JARNAME)
ifneq ($(shell test -e $@ && echo exists),"exists")
	@echo 'Building jni header files'
	@mkdir -p builds/jnih
	javah -d builds/jnih -classpath src org.zeromq.ZMQ
	@echo ' '
endif

builds/obj/%.o: src/%.cpp builds/jnih/%.h
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	@mkdir -p builds/obj
ifeq ($(PLATFORM),Darwin)
	$(CCACHE) g++ -fmessage-length=0 -O3 -arch x86_64 \
	-isysroot /Developer/SDKs/MacOSX10.6.sdk \
	-mmacosx-version-min=10.6 \
	-Ibuilds/jnih \
	-Isrc/third_party -I/usr/local/include \
	-DMACOSX \
	-c -o $@ $<
	@echo "Foo"
endif
ifeq ($(PLATFORM),Linux)
	@echo 'No support for building $< on Linux yet'
endif
	@echo 'Finished building: $<'
	@echo ' '

$(JNILIBNAME): $(OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C++ Linker'
ifeq ($(PLATFORM),Darwin)
	MACOSX_DEPLOYMENT_TARGET="10.6" \
	g++ -arch x86_64 -dynamiclib -isysroot /Developer/SDKs/MacOSX10.6.sdk \
	$(USER_OBJS) $(OBJS) -lpthread \
	-mmacosx-version-min=10.6 -single_module \
	-compatibility_version 1 -current_version 1 \
	-o $(JNILIBNAME)
endif
ifeq ($(PLATFORM),Linux)
	@echo 'No support for building $@ on Linux yet'
endif
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) builds/jnih builds/obj src/org/zeromq/*.class $(JNIBASENAME).* *.jar
	-@echo ' '
