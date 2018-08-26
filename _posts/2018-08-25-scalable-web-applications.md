---
layout: post
title:  "Scalable web applications with swarm"
date:   2018-08-25 12:00:00
categories: swarm docker php laravel
---
Designing horizontal scalable application can be a difficult task if you don't know the right tools to achieve this pourpose. In this post we make use of docker swarm to create an horizontal scalable web application.

##### TL;DR
```bash
docker swarm init && \
git clone https://github.com/mercuriete/laravel-docker-redis.git && \
cd laravel-docker-redis && \
docker stack deploy --compose-file=docker-stack-compose.yml laravel && \
sleep 5 && \
docker service scale laravel_php=2 
```

##### Disclaimer
The scope of this post is not teaching you how to create an application in a given framework. I decided to use php and laravel because I thought was a practical approach instead of making a academic tutorial without real application in real life.

If you had never heard about docker or what is a stateless web application. This topics are out of the scope of this post.

Given that you know what are docker containers or how to create a stateless web application, you can continue, otherwise I will encourage you to read the docs.

[Some docker tutorial](https://docs.docker.com/compose/wordpress/)

[Some definition about Stateless App](https://whatis.techtarget.com/definition/stateless-app)

##### Swarm init
First of all we need to have up and running our docker swarm cluster. In this tutorial we do the examples with a cluster of only one node. You can think this is kind of pointless but in a docker swarm adding more nodes or scaling your application is so easy that once you learn with one node, the rest is the same than with one node.

```bash
docker swarm init
```
output:
```bash
Swarm initialized: current node (RANDOM_STRING) is now a manager.  
To add a worker to this swarm, run the following command:  
docker swarm join --token RANDOM_STRING 192.168.1.43:2377  
To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.  
```

With this command you are ready to deploy swarm stacks.

##### Cloning the repository

```bash
git clone https://github.com/mercuriete/laravel-docker-redis.git
```
##### Understanding the application
This application is a example of a php application with a mysql database and a redis database for authentication.

<img src='https://g.gravizo.com/svg?
 digraph G {
   nginx [shape=box]
   php [shape=box]
   database [shape=box]
   redis [shape=box]
   nginx -> php;
   php -> database;
   php -> redis;
 }
'/>

1. **Nginx**: Nginx is the entry point of our application. It translates all request on something php likes. See [default.conf](https://raw.githubusercontent.com/mercuriete/laravel-docker-redis-nginx/master/default.conf)
2. **Php**: This is our application. Is made with laravel php framework. This is the component we want to scale. This application can potentially have hundreds of request that consumes lots of cpu resources.
3. **Database**: This is our persistence. We need to ensure this container always is back up in a regular basis and uses a persistent volume. How to create persistent volumes is out of scope of this tutorial.
4. **Redis**: This is the mecanism that allows the application to be Stateless. It records all session tokens in order to avoid to have any state on the php application. We don't need to persist the state of redis, but if you lose the redis information, all your customers are logged out from your application. Be careful about how many times you restart this container.

##### Deploying our application
```bash
docker stack deploy --compose-file=docker-stack-compose.yml laravel
```
output:
```bash
Creating network laravel_default  
Creating service laravel_database  
Creating service laravel_redis  
Creating service laravel_nginx  
Creating service laravel_php  
```

Now we have up and running our stack. We can check it with the following command.
```bash
docker service ls
```
output:
```bash
ID NAME MODE REPLICAS IMAGE PORTS  
05kyuuxj36bj laravel_database replicated 0/1 mysql:5.7  
ofgn8q9rmmpw laravel_nginx replicated 0/1 mercuriete/laravel-redis-nginx:latest *:80->80/tcp  
lzdl6gdr9irr laravel_php replicated 0/1 mercuriete/laravel-redis:latest  
39anu4sg762z laravel_redis replicated 1/1 redis:4.0
```

##### Scaling our application
We need to scale our application horizontally in order to comply with the new amount of users that required more performance in our application.
```bash
docker service scale laravel_php=2 
```
output:
```bash
laravel_php scaled to 2  
overall progress: 2 out of 2 tasks  
1/2: running [==================================================>]  
2/2: running [==================================================>]  
verify: Service converged
```
now our application should be like this:

<img src='https://g.gravizo.com/svg?
 digraph G {
   nginx [shape=box]
   routing_mesh [shape=box]
   php1 [shape=box]
   php2 [shape=box]
   database [shape=box]
   redis [shape=box]
   nginx -> routing_mesh;
   routing_mesh -> php1;
   routing_mesh -> php2;
   php1 -> database;
   php1 -> redis;
   php2 -> database;
   php2 -> redis;
 }
'/>

Now we have 2 instances of php behind a load balancer. This balancer is called Ingress and sometimes docker call it _"the routing mesh"_.

You can read more documentation [here](https://docs.docker.com/engine/swarm/ingress/)

![routing mesh](https://docs.docker.com/engine/swarm/images/ingress-routing-mesh.png)

##### Rolling Updates
Rolling updates is a feature of docker swarm that allows you to upgrade your containers with a new release of your code with 0 downtime even in only 1 node cluster.

1. First we have to make a commit of our code and wait to our CI tool to recreate the image and upload It to our registry. We are using dockerhub automated builds to achieve this.
2. Type in the shell the followint command. _Update delay_ is wait until the next instance is recreated. Under the hood swarm is recreating the service one by one with a delay of 30 seconds. This means we have some time the application with both versions of our application at the same time, but is up all the time.
```bash
docker service update laravel_php --update-delay 30s --image mercuriete/laravel-redis  
```
output:
```bash
laravel_php  
overall progress: 2 out of 2 tasks  
1/2: running [==================================================>]  
2/2: running [==================================================>]  
verify: Service converged  
```

##### Conclusions
Nowadays we have more tools to achieve horizontal scaling in web applications.
I remember when I had to configure HAProxy in an 8 node distributed application. It was a nightmare.

In Addition, we can deploy our releases in a way that nobody can realise whether our application is being updated or not.

##### Next steps
In the following post we will be learning to use [**portainer**](https://portainer.io/) to do the same tutorial but with a graphical frontend with a few clicks.

