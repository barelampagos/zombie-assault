/*-------------------------------------------------------------------------------
 * Top Down Shooter - Zombie Assault
 * Author: Bryan Relampagos
 * Interaction Design
 * Fall 2015
 * 
 * Credits:
 * Sound Effects generated with Bfxr: http://www.bfxr.net/
 * Background Music: http://incompetech.com/music/royalty-free/index.html?collection=029
 * "Rhinoceros" Kevin MacLeod (incompetech.com) 
 * Licensed under Creative Commons: By Attribution 3.0
 * http://creativecommons.org/licenses/by/3.0/
/*-------------------------------------------------------------------------------
 
/*-------------------------------------------------------------------------------
 *  Comment out this block if !using Processing 3.0+ & Installed the Sound Library
 *  Also, comment out anything with a .play() 
/*-----------------------------------------------------------------------------*/
import processing.sound.*;
SoundFile hit, shootProjectile, pickUp, backgroundMusic;
// ------------------------------------------------------------------------------

/*--------------------------------*
 * Global Variables 
/*--------------------------------*/
PFont orbitron;
ArrayList<Projectile> projectiles;
ArrayList<Enemy> enemies;
ArrayList<PowerUp> powerups;
boolean gameActive, win, waveComplete, menuDisplay;
int menuTextTime, menuTextCD;
int level, currentWave, currentEnemies, remainingEnemies;
int totalKills, totalShots, score, state, powerUpTime, powerUpCD, startTime;
int hitTime, hitTimeCD;
final int displayTime = 1000;
Player playerCharacter;
XML xml;
XML[] waves;
boolean upPressed, leftPressed, downPressed, rightPressed;

void setup() {
  size(1080, 720);
  orbitron = loadFont("Orbitron-Medium-80.vlw");
  xml = loadXML("waves.xml");
  waves = xml.getChildren("wave");
  gameActive = false;
  cursor(CROSS);
  state = 0;
  powerUpTime = millis();
  powerUpCD = (int) random(10000, 15000);
  menuTextCD = 1000;
  hitTimeCD = 800;
  upPressed = leftPressed = downPressed = rightPressed = false;

  //--- Comment out this block if disabling sound!----
  hit = new SoundFile(this, "Hit.wav");
  shootProjectile =  new SoundFile(this, "ShootProjectile.wav");
  pickUp = new SoundFile(this, "PickupHealth.wav");
  backgroundMusic = new SoundFile(this, "Rhinoceros.mp3");
  //--------------------------------------------------
}

void draw() {
  background(0);
  if (state == 0) {
    drawMenu();
  } else if (state == 1) {
    drawGame();
  } else if (state == 2) {
    gameOver();
  }
}

/*--------------------------------*
 * Functions 
/*--------------------------------*/
// Draws Menu screen
void drawMenu() {
  fill(255);
  textAlign(CENTER);
  rectMode(CENTER);

  if (millis() - menuTextTime > menuTextCD) {
    menuDisplay = !menuDisplay;
    menuTextTime = millis();
  }
  if (menuDisplay == true) {
    textSize(40);
    text("-- Press ENTER to Start --", width/2, height/2 + 50);
  } 

  textFont(orbitron);
  textSize(90);
  fill(#20A714);
  text("Zombie Assault", width/2, height/2 - 100);
  fill(255);
  textSize(20);
  text("By: Bryan Relampagos", width/2, height/2 - 50);
  textSize(25);
  text("Controls: ", width/2 - 200, height/2 + 200);
  stroke(255);
  strokeWeight(3);
  line(width/2 - 270, height/2 + 210, width/2 - 130, height/2 + 210);
  textSize(20);
  text("W A S D / Arrow Keys: Move", width/2 - 200, height/2 + 250);
  text("Mouse: Aim and Shoot", width/2 - 200, height/2 + 300);
  text("How to Play: ", width/2 + 200, height/2 + 200);
  stroke(255);
  strokeWeight(3);
  line(width/2 + 130, height/2 + 210, width/2 + 270, height/2 + 210);
  text("Shoot -->", width/2 + 200, height/2 + 250);
  text("Collect -->", width/2 + 200, height/2 + 300);

  // Enemy sprite
  stroke(1, 82, 0); 
  fill(0, 255, 0);
  ellipse(width/2 + 280, height/2 + 245, 30, 30);

  // Health sprite
  stroke(255, 0, 0);
  fill(255, 0, 0, 90);
  ellipse(width/2 + 280, height/2 + 300, 30, 30);
  stroke(255);
  fill(255);
  line(width/2 + 270, height/2 + 300, width/2 + 290, height/2 + 300);
  line(width/2 + 280, height/2 + 290, width/2 + 280, height/2 + 310);

  // MachineGun sprite
  stroke(255);
  fill(255, 90);
  ellipse(width/2 + 320, height/2 + 300, 30, 30);
  stroke(255);
  fill(255);
  ellipse(width/2 + 312, height/2 + 300, 4, 4);
  ellipse(width/2 + 320, height/2 + 300, 4, 4);
  ellipse(width/2 + 328, height/2 + 300, 4, 4);

  // Laser Sprite
  stroke(255);
  fill(255, 90);
  ellipse(width/2 + 360, height/2 + 300, 30, 30);
  stroke(0, 0, 255);
  line(width/2 + 352, height/2 + 300, width/2 + 368, height/2 + 300);
}

// Draws game over screen
void gameOver() {
  textSize(50);
  if (win) {
    fill(#00F00D);
    text("Congratulations! You Win!", width/2, height/2 - 100);
  } else {
    fill(#FF0000);
    text("Game Over", width/2, height/2 - 100);
  }
  fill(255);
  textSize(40);
  text("Survived until Wave " + currentWave, width/2, height/2 - 50);
  text("-- Press ENTER to Restart --", width/2, height/2);
  textSize(30);
  text("Total  Kills: " + totalKills, width/2, height/2 + 100);
  text("Shots Fired: " + totalShots, width/2, height/2 + 150);
  text("Hit Accuracy: " + round(((float)totalKills / (float) totalShots)*100) + "%", width/2, height/2 + 200);
  textSize(38);
  text("Final Score: " + score, width/2, height/2 + 300);
}

// Draws all game components
void drawGame() {
  if (!gameActive) {
    initializeGame();
  }
  playerCharacter.update();
  updateProjectiles();
  pushMatrix();
  drawPlayer();
  popMatrix();
  updatePowerups();
  updateEnemies();
  drawText();
  collisionHandler();
}

// Initializes all global variables for a new wave
void initializeGame() {
  projectiles = new ArrayList<Projectile>();
  enemies = new ArrayList<Enemy>();
  powerups = new ArrayList<PowerUp>();
  currentWave = waves[level].getInt("id");
  currentEnemies = waves[level].getInt("enemies");
  remainingEnemies = currentEnemies;
  gameActive = true;
}

// Handles drawing and rotation of player character + the laser aim
void drawPlayer() {
  // Laser between player & mouse
  strokeWeight(.5);
  stroke(255, 0, 0);
  line(mouseX, mouseY, playerCharacter.location.x, playerCharacter.location.y);

  fill(playerCharacter.fill);
  stroke(playerCharacter.stroke);
  playerCharacter.angle = atan2(playerCharacter.location.x - mouseX, playerCharacter.location.y - mouseY);
  translate(playerCharacter.location.x, playerCharacter.location.y);
  rotate(-playerCharacter.angle-PI); 
  strokeWeight(4);
  ellipse(0, 0, 50, 50);
  line(0, 10, 0, 40);
}

// Draws game text 
void drawText() {
  textSize(30);
  fill(255);
  textAlign(CENTER);

  //TOP TEXT
  text("Health", width*.25, 30);
  stroke(255, 0, 0);
  fill(255, 0, 0, 90);
  for (int i = 0; i < playerCharacter.health; i++) {
    ellipse(width*.22 + (40 * i), 50, 30, 30);
  }
  fill(255);
  text("Score", width/2, 30); 
  text(score, width/2, 70);
  text("Remaining  Enemies:", width*.75, 30); 
  text(remainingEnemies, width*.75, 70);

  //BOTTOM TEXT
  text("Wave", width/2, height - 70); 
  text(currentWave, width/2, height - 30);

  if (playerCharacter.projectileCD != 250) { 
    fill(255);
    textSize(40);
    text(playerCharacter.ammo, width - 100, height - 70);
  }

  if (waveComplete) {
    fill(#00F00D); // Filled with F00D
    textSize(60);
    text("Wave Complete", width/2, height/2);
    if (millis() - startTime > displayTime)
    { 
      waveComplete = false;
    }
  }
}

// Handles transitioning from menu to menu
void keyPressed() {
  if (state == 0 && (key == RETURN || key == ENTER)) {
    backgroundMusic.play();
    state = 1;
    playerCharacter = new Player();
    playerCharacter.location = new PVector(width/2, height/2);
    totalKills = 0;
    level = 0;
    score = 0;
    totalShots = 0;
  } else if (state == 1) {
    switch(key) {
      case('w') : 
      case('W') :
      upPressed = true;
      break; 
      case('a') : 
      case('A') : 
      leftPressed = true;      
      break; 
      case('s') : 
      case('S') :
      downPressed = true;      
      break; 
      case('d') : 
      case('D') : 
      rightPressed = true;      
      break;
    }
    if (keyCode == UP) {
      upPressed = true;
    } else if (keyCode == LEFT) {
      leftPressed = true;
    } else if (keyCode == DOWN) {
      downPressed = true;
    } else if (keyCode == RIGHT) {
      rightPressed = true;
    }
    //} else if (key == 'p') {
    //  powerups.add(new PowerUp(new PVector(random(50, width), random(50, height)), playerCharacter));
    //}
  } else if (state == 2 && (key == RETURN || key == ENTER)) {
    state = 0;
    backgroundMusic.stop();
  }
}

void keyReleased() {
  switch(key) {
    case('w') : 
    case('W') :
    upPressed = false;
    break; 
    case('a') : 
    case('A') : 
    leftPressed = false;      
    break; 
    case('s') : 
    case('S') :
    downPressed = false;      
    break; 
    case('d') : 
    case('D') : 
    rightPressed = false;      
    break;
  }
  if (keyCode == UP) {
    upPressed = false;
  } else if (keyCode == LEFT) {
    leftPressed = false;
  } else if (keyCode == DOWN) {
    downPressed = false;
  } else if (keyCode == RIGHT) {
    rightPressed = false;
  }
}

// Updates the projectiles every frame iteration
// Also removes projectiles that have gone off screen
void updateProjectiles() {
  for (int i = 0; i < projectiles.size (); i++) {
    Projectile p = projectiles.get(i);
    p.update();

    if (p.location.x < 0 || p.location.x > width || p.location.y < 0 || p.location.y > height || p.active == false) {
      projectiles.remove(i);
    }
  }
}

// Spawns enemies and updates them every frame iteration
void updateEnemies() {
  int m = millis();
  if (m % 30 == 0 && currentEnemies > 0) {
    spawnEnemy();
  }
  for (int i = 0; i < enemies.size (); i++) {
    Enemy e = enemies.get(i);
    e.update();
  }
  if (remainingEnemies == 0 && level < waves.length - 1) {
    level++;
    startTime = millis();
    gameActive = false;
    waveComplete = true;
  } else if (remainingEnemies == 0 && level == waves.length - 1) {     // All levels beaten
    gameActive = false;
    win = true;
    state = 2;
  }
}

// Spawns a new enemy in one of 4 sections off screen
void spawnEnemy() {
  int r = (int) random(0, 4);
  color c = color(0, random(200, 255), 0);
  if (r == 0) {
    enemies.add(new Enemy(new PVector(random(-200, 0), random(-200, height+200)), playerCharacter, c));
  } else if (r == 1) {
    enemies.add(new Enemy(new PVector(random(width, width + 200), random(-200, height+200)), playerCharacter, c));
  } else if (r == 2) {
    enemies.add(new Enemy(new PVector(random(width - 200, width + 200), random(height, 200)), playerCharacter, c));
  } else {
    enemies.add(new Enemy(new PVector(random(width - 200, width + 200), random(-200, 0)), playerCharacter, c));
  }
  currentEnemies--;
}

// Spawns powerups
void updatePowerups() {
  if (millis() - powerUpTime > powerUpCD) {
    powerups.add(new PowerUp(new PVector(random(0, width), random(0, height)), playerCharacter));
    println("Spawned powerup!");
    powerUpCD = (int) random(10000, 15000);
    powerUpTime = millis();
  }

  for (int i = 0; i < powerups.size (); i++) {
    powerups.get(i).update();
  }
}

// Checks projectile and enemy collision
void collisionHandler() {
  for (int i = projectiles.size () - 1; i >= 0; i--) {
    for (int j = enemies.size () - 1; j >= 0; j--) {
      Projectile p = projectiles.get(i);
      Enemy e = enemies.get(j);
      if (p.active && e.active && checkCollision(p.location.x, p.location.y, e.location.x, e.location.y, 20)) {
        hit.play();
        totalKills++;
        score += 100;
        remainingEnemies--;
        p.active = false;
        e.active = false;
      }
    }
  }
}

// Helper function for simplifying collision detection
boolean checkCollision(float x, float y, float x2, float y2, float r) {
  if (dist(x, y, x2, y2) < r) {
    return true;
  } else {
    return false;
  }
}

/*--------------------------------*
 * Classes 
/*--------------------------------*/
class Player {
  PVector location; 
  int movementSpeed;
  float angle;
  color fill, stroke, projectileFill;
  int health, maxHealth, lastProjectileTime, projectileCD, ammo;
  boolean hitCooldown = false;

  Player() {
    movementSpeed = 5; 
    angle = 0; 
    stroke = color(#FFFFFF);
    fill  = color(0);
    health = 5;
    maxHealth = health;
    projectileCD = 250;
    projectileFill = color(255);
  }

  void update() {
    // Handles Movement and constrains player to the screen
    if (upPressed && location.y - movementSpeed > 0) {
      location.y -= movementSpeed;
    } 
    if (leftPressed && location.x - movementSpeed > 0) { 
      location.x -= movementSpeed;
    } 
    if (downPressed && location.y + movementSpeed < height) {
      location.y += movementSpeed;
    } 
    if (rightPressed && location.x + movementSpeed < width) {
      location.x += movementSpeed;
    }

    // Provides a hit cooldown so player cannot die instantaneously
    if (hitCooldown) {
      playerCharacter.stroke = color(255, 0, 0);
      if (millis() - hitTime > hitTimeCD) {
        hitCooldown = false;
        playerCharacter.stroke = color(255);
      }
    }

    // If the player loses all their health, game over
    if (health <= 0) {
      gameActive = false;
      win = false;
      state = 2;
    }

    // Enables shooting
    if (mousePressed) {
      if (millis() - lastProjectileTime > projectileCD) {
        PVector mouseLoc = new PVector(mouseX, mouseY);
        PVector initialLoc = new PVector(location.x, location.y);
        shootProjectile.play();
        projectiles.add(new Projectile(playerCharacter, projectileFill, initialLoc, mouseLoc));
        totalShots++;
        if (ammo > 0) {
          ammo--;
          if (ammo == 0) {
            projectileCD = 250;
            projectileFill = color(255);
          }
        }
        lastProjectileTime = millis();
      }
    }
  }
}


class Projectile {
  Player p;
  color projectileFill;
  PVector location, trajectory, mouseLoc; 
  float speed; 
  int size;
  boolean active;

  Projectile(Player p, color projectileFill, PVector location, PVector mouseLoc) {
    this.p = p;
    this.location = location; 
    this.mouseLoc = mouseLoc; 
    active = true;
    speed = 12; 
    size = 5;
    this.projectileFill = projectileFill;
    trajectory = PVector.sub(mouseLoc, location); 
    trajectory.normalize(); 
    trajectory.mult(speed);
  } 

  void update() {
    if (active) {
      location.add(trajectory); 
      stroke(projectileFill); 
      fill(projectileFill); 
      ellipse(location.x, location.y, size, size);
    }
  }
}

class Enemy {
  PVector location, direction; 
  Player p;
  int size, speed;
  boolean active;
  color fill;

  Enemy(PVector location, Player p, color fill) {
    this.location = location;
    this.p = p;
    size = 50;
    speed = (int) random(2, 4);
    active = true;
    direction = new PVector(0, 0);
    this.fill = fill;
  }

  void update() {
    if (active) {
      stroke(1, 82, 0); 
      fill(fill); 

      if (dist(p.location.x, p.location.y, location.x, location.y) > 50) {
        direction.x = p.location.x - location.x;
        direction.y = p.location.y - location.y;
        direction.normalize();
        location.x += direction.x * speed;
        location.y += direction.y * speed;
      } else {
        if (p.hitCooldown == false) {
          hit.play();
          p.health--;
          hitTime = millis();
          p.hitCooldown = true;
        }
      }
      ellipse(location.x, location.y, size, size);
    }
  }
}

class PowerUp {
  PVector location; 
  Player p;
  int size;
  boolean active;
  int id;

  PowerUp(PVector location, Player p) {
    this.location = location;
    this.p = p;
    size = 30;
    id = (int) random(0, 3);
    active = true;
  }

  void update() {
    if (active) {
      if (id == 0) {
        stroke(255, 0, 0);
        fill(255, 0, 0, 90);
        ellipse(location.x, location.y, size, size);
        stroke(255);
        fill(255);
        line(location.x - 10, location.y, location.x + 10, location.y);
        line(location.x, location.y - 10, location.x, location.y + 10);
      } else if (id == 1) {
        stroke(255);
        fill(255, 90);
        ellipse(location.x, location.y, size, size);
        stroke(255);
        fill(255);
        ellipse(location.x - 8, location.y, 4, 4);
        ellipse(location.x, location.y, 4, 4);
        ellipse(location.x + 8, location.y, 4, 4);
      } else if (id == 2) {
        stroke(255);
        fill(255, 90);
        ellipse(location.x, location.y, size, size);
        stroke(0, 0, 255);
        line(location.x - 8, location.y, location.x + 8, location.y);
      }

      if (checkCollision(p.location.x, p.location.y, location.x, location.y, size)) {
        pickUp.play();
        if (id == 0) {
          if (p.health < p.maxHealth) {
            p.health += 1;
          }
        } else if (id == 1) {
          p.projectileCD = 100;
          p.ammo = 50;
          p.projectileFill = color(255);
        } else if (id == 2) {
          p.projectileCD = 25;
          p.ammo = 20;
          p.projectileFill = color(0, 0, 255);
        }
        active = false;
      }
    }
  }
}