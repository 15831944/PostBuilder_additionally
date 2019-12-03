%define name tknotepad
%define version 0.7.8
%define release 1
%define packager Joseph Acosta

Summary: A simple notepad like text editor.
Name: %{name}
Version: %{version}
Release: %{release}
Copyright: GPLish, Tcl/Tk ?
Group: Applications/Editors
Source: %{name}-%{version}.tar.gz
Buildroot: /tmp/%{name}-build
URL: http://www.mindspring.com/~joeja/programs.html

%description
This is a simple text editor. I have tried to incorporate most of the same features as Window Notepad, with a few added features. I have added unlimited Undo/Redo, thank to the borrowed code. It now accepts pipes (UNIX only) and can open multiple files from the command line.  I have also refined the code a bit, and thanks to many others for there bug reports. Thank you , Joseph Acosta.

%prep

%setup 

%build

%install
mkdir $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT/usr
mkdir $RPM_BUILD_ROOT/usr/local
mkdir $RPM_BUILD_ROOT/usr/local/bin
cp tknotepad $RPM_BUILD_ROOT/usr/local/bin/

%files
/usr/local/bin/tknotepad
%doc README
%doc license.txt
%doc README.help
%doc HOWTO-COMMAND-LINE-OPTIONS
%doc INSTALL
%doc KNOWNISSUES
