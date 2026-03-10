FROM rockylinux:9

RUN yum -y update && \
    yum -y install epel-release zlib-devel bzip2-devel xz-devel ncurses-devel pango-devel && \
    yum -y install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm && \
    yum -y install mysql httpd perl perl-CGI perl-GD perl-DBD-MySQL libgomp && \
	yum clean all

RUN echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf
RUN echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf

EXPOSE 80

# Simple startup script to avoid some issues observed with container restart
ADD run-httpd.sh /run-httpd.sh
RUN chmod -v +x /run-httpd.sh

CMD ["/run-httpd.sh"]
