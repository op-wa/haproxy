include:
  - modules.haproxy.rsyslog

install-dep-haproxy:
  pkg.installed:
    - pkgs:
      - make
      - gcc
      - pcre-devel
      - bzip2-devel
      - openssl-devel
      - systemd-devel

haproxy:
  user.present:
    - system: true
    - createhome: false
    - shell: /sbin/nologin

/usr/src:
  archive.extracted:
    - source: salt://modules/haproxy/files/haproxy-{{ pillar['haproxy_version'] }}.tar.gz
    
haproxy-install:
  cmd.script:
    - name: salt://modules/haproxy/files/install.sh.j2
    - template: jinja
    - require:
      - archive: /usr/src
    - unless: test -d {{ pillar['haproxy_install_dir'] }}

/etc/profile.d/haproxy.sh:
  file.managed:
    - source: salt://modules/haproxy/files/haproxy.sh.j2
    - template: jinja

/etc/sysctl.conf:
  file.append:
    - text: 
      - net.ipv4.ip_nonlocal_bind = 1
      - net.ipv4.ip_forward = 1
  cmd.run:
    - name: sysctl -p

{{ pillar['haproxy_install_dir'] }}/conf:
  file.directory:
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true
    - require: 
      - cmd: haproxy-install

{{ pillar['haproxy_install_dir'] }}/conf/haproxy.cfg:
  file.managed:
    - source: salt://modules/haproxy/files/haproxy.cfg.j2
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - require:
      - file: {{ pillar['haproxy_install_dir'] }}/conf

/usr/lib/systemd/system/haproxy.service:
  file.managed:
    - source: salt://modules/haproxy/files/haproxy.service.j2
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja

haproxy.service:
  service.running:
    - enable: true
    - reload: true
    - require: 
      - file: /usr/lib/systemd/system/haproxy.service
      - file: {{ pillar['haproxy_install_dir'] }}/conf/haproxy.cfg
      - cmd: haproxy-install
      - archive: /usr/src
    - watch:
      - file: /usr/lib/systemd/system/haproxy.service


 
