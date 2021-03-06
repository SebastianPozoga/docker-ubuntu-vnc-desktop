#!/bin/bash

mkdir -p /var/run/sshd

chown -R root:root /root
mkdir -p /root/.config/pcmanfm/LXDE/
cp /usr/share/doro-lxde-wallpapers/desktop-items-0.conf /root/.config/pcmanfm/LXDE/

if [ -n "$VNC_PASSWORD" ]; then
  echo -n "$VNC_PASSWORD" > /.password1
  x11vnc -storepasswd $(cat /.password1) /.password2
  chmod 400 /.password*
  sed -i 's/^command=x11vnc.*/& -rfbauth \/.password2/' /etc/supervisor/conf.d/supervisord.conf
  export VNC_PASSWORD=
fi

if [ -n "$VNC_SCREEN" ]; then
  find /etc/supervisor/conf.d/supervisord.conf -type f -exec sed -i -e "s/^command\=\/usr\/bin\/Xvfb.*$/command\=\/usr\/bin\/Xvfb :1 -screen 0 $VNC_SCREEN/" {} \;
fi

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  ssh-keygen -f "$HOME/.ssh/id_rsa" -t rsa -N ''
fi

if [ ! -f "$HOME/Desktop/autorun.sh" ]; then
  chmod +x "$HOME/Desktop/autorun.sh"
  sh "$HOME/Desktop/autorun.sh"
fi

cd /usr/lib/web && ./run.py > /var/log/web.log 2>&1 &
nginx -c /etc/nginx/nginx.conf
exec /bin/tini -- /usr/bin/supervisord -n
