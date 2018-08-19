FROM jekyll/jekyll:latest

RUN apk update \
	&& apk add py-pip \
	&& pip install --upgrade pip \
	&& gem install rouge pygments.rb redcarpet

EXPOSE 4000

WORKDIR /srv/jekyll

CMD ["jekyll", "server"]

ADD . /srv/jekyll
