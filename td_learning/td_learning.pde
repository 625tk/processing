

final int WINDOW_WIDTH = 600;
final int WINDOW_HEIGHT= 600;

final int CELL_TYPE_WALL = 0;
final int CELL_TYPE_ROAD = 1;
final int CELL_TYPE_START= 2;
final int CELL_TYPE_GOAL = 3;

final int LABYRINTH_WIDTH = 9;
final int LABYRINTH_HEIGHT= 9;
final int[] dx = {0,0,1,-1};
final int[] dy = {1,-1,0,0};

final float EPS = 0.1;
final float LEARN_ALPHA = 0.2;
final float LEARN_GAMMA = 0.7;


final int CELL_SIZE = WINDOW_WIDTH/LABYRINTH_WIDTH;

Cell[][] labyrinth = new Cell[LABYRINTH_HEIGHT][LABYRINTH_WIDTH];
pair[][] check = new pair[LABYRINTH_HEIGHT][LABYRINTH_WIDTH];

pair START;
pair GOAL;

Agent agent;


//初期化する
void setup(){
  //setup
  frameRate(30);
  size(600, 600);

  //迷路の初期化
  for(int i = 0; i < LABYRINTH_HEIGHT; ++i){
    for(int j = 0; j < LABYRINTH_WIDTH; ++j){
      int type = CELL_TYPE_ROAD;
      if(i == 0 || i+1 == LABYRINTH_HEIGHT ||
          j == 0 || j+1 == LABYRINTH_WIDTH || (int)random(3) == 0) type = CELL_TYPE_WALL;
      labyrinth[i][j] = new Cell(j, i, type);
    }
  }
  
  int mx = 0;
  for(int i = 0; i < LABYRINTH_HEIGHT; ++i){
    for(int j = 0; j < LABYRINTH_WIDTH; ++j){
      check[i][j] = new pair(-1,-1);
    }
  }

  //最大領域を探す
  for(int i = 0; i < LABYRINTH_HEIGHT; ++i){
    for(int j = 0; j < LABYRINTH_WIDTH; ++j){
      if(check[i][j].x == -1){
        if(labyrinth[i][j].type != CELL_TYPE_WALL){
          int sz = bfs(j,i);
          if(mx < sz){
            mx = sz;
            START = new pair(check[i][j]);
          }
        }
      }
    }
  }

  //最大領域の一番遠いところ同士を迷路のスタート，ゴールにする
  for(int i = 0; i < LABYRINTH_HEIGHT; ++i){
    for(int j = 0; j < LABYRINTH_WIDTH; ++j){
      check[i][j] = new pair(-1,-1);
    }
  }

  bfs(START.x, START.y);
  GOAL = check[START.y][START.x];
  if(GOAL.x == -1){
    GOAL.x = 0;
    GOAL.y = 0;
  }

  labyrinth[START.y][START.x].type = CELL_TYPE_START;
  labyrinth[GOAL.y][GOAL.x].type = CELL_TYPE_GOAL;
  labyrinth[GOAL.y][GOAL.x].set_weight();

  agent = new Agent(START);
}

int bfs(int x, int y){
  SimpleQueue q = new SimpleQueue();
  int total = 0;
  pair p = new pair(x, y);
  pair last = new pair(1,1);
  q.push(p);
  int sz = q.items;
  int distance = 0;
  while(sz != 0){
    sz = q.items;
    total += sz;
    for(int i = 0; i < sz; ++i){
      p = q.pop();
      last.x=p.x;
      last.y=p.y;
      for(int j = 0; j < 4; ++j){
        int nx = p.x + dx[j];
        int ny = p.y + dy[j];
        if(!range_check(nx, ny))continue;
        if( labyrinth[ny][nx].type != CELL_TYPE_WALL){
          if(check[ny][nx].x == -1){
            check[ny][nx].x = 1;
            check[ny][nx].y = 1;
            q.push(new pair(nx, ny));
          }
        }
      }
    }
  }
  check[y][x] = new pair(last);
  return total;
}

boolean range_check(int x, int y){
  if( x < 0 || y < 0 || x >= LABYRINTH_WIDTH || y >= LABYRINTH_HEIGHT)return false;
  return true;
};



void draw(){
  //描画
  agent.move();
  for(int i = 0; i < LABYRINTH_HEIGHT; ++i){
    for(int j = 0; j < LABYRINTH_WIDTH; ++j){
      labyrinth[i][j].draw();
    }
  }
  agent.draw();
  if(agent.is_reached()){
    agent.update_cells();
    agent = new Agent(START);
  }
}


//迷路のマスを表現するクラス
class Cell{
  int type;
  float r, v;
  int x, y;

  Cell(int index_x, int index_y, int _type){
    type = _type;
    x = index_x;
    y = index_y;
    r = -1;
    v = -1;
  }

  void set_weight(){
    v = 10000;
  }
  void draw(){
    switch(type){
      case CELL_TYPE_ROAD:
        fill(0);
        break;
      case CELL_TYPE_WALL:
        fill(128,128,128);
        break;
      case CELL_TYPE_START:
        fill(0, 0,128);
        break;
      case CELL_TYPE_GOAL:
        fill(128, 0, 0);
        break;
    }
    rect(x*CELL_SIZE, y*CELL_SIZE, CELL_SIZE, CELL_SIZE);
  }

  boolean is_wall(){
    if( type == CELL_TYPE_WALL){
      return true;
    }
    return false;
  }
  
  void update(float nex_r, float nex_v){
    v = v + LEARN_ALPHA * (nex_r + LEARN_GAMMA*nex_v- v);
  }
}

class Agent{
  pair position;
  ArrayList<pair> history;

  Agent(pair p){
    history = new ArrayList<pair>();
    position = new pair(p);
  }

  void draw(){
    fill(255);
    rect(position.x*CELL_SIZE+CELL_SIZE/4, position.y*CELL_SIZE+CELL_SIZE/4,
        CELL_SIZE/2, CELL_SIZE/2);
  }

  void move(){
    history.add(new pair(position));
    int dir, x = 0, y = 0;
    float mx = 0;
    for(int i = 0; i < 4; i++){
      if(range_check(dx[i] + position.x, dy[i] + position.y)){
        if( !labyrinth[dy[i] + position.y][dx[i] + position.x].is_wall() && 
            labyrinth[dy[i] + position.y][dx[i] + position.x].v > mx){
          mx = labyrinth[dy[i] + position.y][dx[i] + position.x].v;
          x = dx[i];
          y = dy[i];
        }
      }
    }
    if((x == 0 && y == 0) || EPS > random(1)){
      while(true){
        dir = (int)random(4);
        x = 0; y = 0;
        switch(dir){
          case 0:
            x=-1;
            break;
          case 1:
            x=+1;
            break;
          case 2:
            y=-1;
            break;
          default:
            y=1;
            break;
        }
        if(range_check(x + position.x, y + position.y)
           && !labyrinth[y+position.y][x+position.x].is_wall()){
            break;
        }
      }
    }
    position.x += x;
    position.y += y;
  }

  boolean is_reached(){
    if(position.x == GOAL.x && position.y == GOAL.y){
      return true;
    }
    return false;
  }
  void update_cells(){
    history.add(new pair(position));
    for(int i = history.size()-2; i >= 0; --i){
      int pos_x = history.get(i).x;
      int pos_y = history.get(i).y;
      int nx = history.get(i+1).x;
      int ny = history.get(i+1).y;
      labyrinth[pos_y][pos_x].update(labyrinth[ny][nx].r, labyrinth[ny][nx].v);
    }
  }
}

//座標表すのに便利なペア
class pair{
  int x, y;
  pair(int xx, int yy){
    x = xx;
    y = yy;
  }
  pair(pair p){
    x = p.x;
    y = p.y;
  }
}

//queue
class SimpleQueue{
  final int SIZE = LABYRINTH_WIDTH*LABYRINTH_HEIGHT;
  pair[] ring = new pair[SIZE];
  int bottom, head;
  int items;

  SimpleQueue(){
    bottom = 0;
    head = 0;
    items = 0;
  }
  pair pop(){
    if(items < 1){
      exit();
    }
    bottom++;bottom%=SIZE;
    items--;
    return ring[(bottom+SIZE-1)%SIZE];
  }

  void push(pair p){
    ring[head] = p;
    head++;head%= SIZE;
    items++;
  }
}

