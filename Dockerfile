FROM jekyll/jekyll:latest

MAINTAINER Jérôme Lecorvaisier <github@lecorvaisier.fr>

RUN apk update \
	&& apk add py-pip \
	&& pip install --upgrade pip \
	&& gem install rouge pygments.rb redcarpet

EXPOSE 4000

VOLUME /srv/jekyll

WORKDIR /srv/jekyll

CMD ["jekyll", "server"]
