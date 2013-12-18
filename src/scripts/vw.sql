
CREATE DATABASE vw;
GRANT ALL ON vw.* TO 'vw'@'localhost' IDENTIFIED BY 'videowall';
flush privileges;

use vw;
CREATE TABLE videos(id INT NOT NULL AUTO_INCREMENT, 
        PRIMARY KEY(id),
        location VARCHAR(255) NOT NULL,
        image VARCHAR(255) NOT NULL,
        annotation VARCHAR(50)
);

#insert into videos (
#        id, 
#        location, 
#        image, 
#        annotation 
#        ) 
#        values (
#        0, 
#        'http://alpha.groovy.org/thumbs/test.flv', 
#        'http://alpha.groovy.org/full/test.flv', 
#        'This is the test video'
#);

