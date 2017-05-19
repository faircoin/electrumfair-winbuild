FROM ubuntu:14.04
MAINTAINER tom@fair-coin.org

RUN locale-gen en_GB.UTF-8
ENV LANG=en_GB.UTF-8
ENV TERM=xterm
ENV MIRROR="at"

RUN sed -i "s/archive\.ubuntu\.com/${MIRROR}\.archive\.ubuntu\.com/g" /etc/apt/sources.list
#RUN sed -i "s/archive\.ubuntu\.com/172.17.0.1:3142\/${MIRROR}\.archive\.ubuntu\.com/g" /etc/apt/sources.list # use with apt-cache-ng
RUN apt-get update -y && apt-get upgrade -y && \
 apt-get install -y software-properties-common dialog gettext vnc4server icewm xterm wget xvfb && add-apt-repository -y ppa:ubuntu-wine/ppa && \
 dpkg --add-architecture i386
RUN sed -i "s/ppa\.launchpad\.net/ppa\.launchpad\.net/g" /etc/apt/sources.list.d/ubuntu-wine-ppa-trusty.list
#RUN sed -i "s/ppa\.launchpad\.net/172.17.0.1:3142\/ppa\.launchpad\.net/g" /etc/apt/sources.list.d/ubuntu-wine-ppa-trusty.list # use with apt-cache-ng

RUN apt-get update -y && \
 apt-get install -y wine1.7 winbind && \
 apt-get purge -y python-software-properties && \
 apt-get autoclean -y

# Versions
ENV PYTHON_URL https://www.python.org/ftp/python/2.7.8/python-2.7.8.msi
ENV PYQT4_URL http://downloads.sourceforge.net/project/pyqt/PyQt4/PyQt-4.11.1/PyQt4-4.11.1-gpl-Py2.7-Qt4.8.6-x32.exe
ENV PYWIN32_URL http://sourceforge.net/projects/pywin32/files/pywin32/Build%20219/pywin32-219.win32-py2.7.exe/download
ENV PYINSTALLER_URL https://pypi.python.org/packages/source/P/PyInstaller/PyInstaller-2.1.zip
ENV NSIS_URL http://prdownloads.sourceforge.net/nsis/nsis-2.46-setup.exe?download
ENV SETUPTOOLS_URL https://pypi.python.org/packages/2.7/s/setuptools/setuptools-0.6c11.win32-py2.7.exe

# Paths
ENV WINEPREFIX /opt/wine-electrum
RUN export WINEPREFIX=/opt/wine-electrum

ENV ELECTRUM_PATH $WINE_PREFIX/drive_c/electrum
ENV PYHOME c:/Python27
ENV PYTHON xvfb-run -a wine $PYHOME/python.exe -B
ENV PIP $PYTHON -m pip
ENV WINEDLLOVERRIDES "mscoree,mshtml="

VOLUME ["/opt/wine-electrum/drive_c/electrum"]

# Install stuff
RUN wget -nv -O python.msi "$PYTHON_URL" && \
 wget -nv -O pyinstaller.zip "$PYINSTALLER_URL" && unzip pyinstaller.zip && mv PyInstaller-2.1 $WINEPREFIX/drive_c/pyinstaller && \
 wget -nv -O pywin32.exe "$PYWIN32_URL" && \
 wget -nv -O PyQt.exe "$PYQT4_URL" && \
 wget -nv -O nsis.exe "$NSIS_URL" && \
 wget -nv -O setuptools.exe "$SETUPTOOLS_URL"

RUN echo "Now start a VNC connetion to this docker on port 5933 with password 'buildit'"

# Only needed for debugging
RUN ( export DISPLAY=:33 && touch /root/.Xauthority && \
 ( echo buildit ; echo buildit ) | vnc4passwd && \
 vnc4server -geometry 1024x768 -depth 24 -name "Server" :33 ; \
 wineboot && sleep 5 && \
 wine msiexec /q /i python.msi && sleep 3 && \
 wineboot && sleep 3 && \
 rm -rf /tmp/.wine-* && wine PyQt.exe /S && sleep 3 && \
 rm -rf /tmp/.wine-* && wine pywin32.exe && sleep 3 && \
 rm -rf /tmp/.wine-* && wine setuptools.exe && sleep 3 && \
 rm -rf /tmp/.wine-* && wine nsis.exe /S && sleep 3 \
)

RUN cp $WINEPREFIX/drive_c/windows/system32/msvcp90.dll $WINEPREFIX/drive_c/Python27/ && \
 cp $WINEPREFIX/drive_c/windows/system32/msvcm90.dll $WINEPREFIX/drive_c/Python27/

ADD ./helpers/build-binary /usr/bin/build-binary

# Clean up stale wine processes
RUN rm -rf /tmp/.wine-* /tmp/.X11-unix/X33 /tmp/.X33-lock

