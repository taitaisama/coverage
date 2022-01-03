// Written in the D programming language.

// Copyright: Coverify Systems Technology 2016
// License:   Distributed under the Boost Software License, Version 1.0.
//            (See accompanying file LICENSE_1_0.txt or copy at
//            http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Puneet Goel <puneet@coverify.com>

module esdl.rand.cover;
// import std.stdio;
// Coverage
//import esdl.rand.misc;

static string doParse(T)(string Bins){
  parser!T Parser = parser!T(Bins);
  return Parser.parse();
}

/* enum Type: bool {SINGLE, MULTIPLE}; */
class CoverGroup {
  Parameters option;
  static StaticParameters type_option;
}
// string Initialise (T)(T grp) if (is(T: CoverGroup)){
//   import std.typecons: Tuple;
//   import std.conv;
//   auto tup = grp.tupleof;
//   string str = "";
//   foreach (i, ref elem; tup){
//     if (!(elem is null)){
//       return "";
//     }
//     str ~= ("tup["~to!string(i)~"] = new "~typeof(elem).stringof~ "();");
//   }
//   return str;
// }

void sample (T)(T grp) if (is(T: CoverGroup)){
  foreach (ref elem; grp.tupleof){
    if (!elem.isCross()){
      elem.sample();
    }
  }
  foreach (ref elem; grp.tupleof){
    if (elem.isCross()){
      elem.sample();
    }
  }
 }
void sample (T)(T grp) if (!is(T: CoverGroup)){
  foreach (ref elem; grp.tupleof){
    static if (is(typeof(elem): CoverGroup)){
      sample(elem);
    }
  }
 }
double get_coverage (T)(T grp) if (is(T: CoverGroup)){
  double total = 0;
  size_t weightSum = 0;
  foreach (ref elem; grp.tupleof){
    total += elem.get_coverage()*elem.get_weight();
    weightSum += elem.get_weight();
  }
  return total/weightSum;
 }
double get_inst_coverage (T)(T grp) if (is(T: CoverGroup)){
  double total = 0;
  size_t weightSum = 0;
  foreach (ref elem; grp.tupleof){
    total += elem.get_inst_coverage()*elem.get_weight();
    weightSum += elem.get_weight();
  }
  return total/weightSum;
 }
void start (T)(T grp) if (is(T: CoverGroup)){
  foreach (ref elem; grp.tupleof){
    elem.start();
  }
 }
void stop (T)(T grp) if (is(T: CoverGroup)){
  foreach (ref elem; grp.tupleof){
    elem.stop();
  }
 }
struct parser (T){
  import std.conv;
  enum BinType: byte {SINGLE, DYNAMIC, STATIC};
  size_t srcCursor = 0;
  size_t outCursor = 0;
  size_t srcLine = 0;
  string outBuffer = "";
  string BINS;

  this(string bins){
    BINS = bins;
  }
  void fill(in string source) {
    //import std.stdio;
    //pragma(source);
    outBuffer ~= source;
  }
  void parseComma(){
    if(BINS[srcCursor] != ','){
      assert(false, "did not add comma in bins range at line " ~ srcLine.to!string);
    }
    ++srcCursor;
    parseSpace();
  }
  bool parseRangeType(){
    if(BINS[srcCursor] == ':'){
      ++ srcCursor;
      return true;
    }
    else if(BINS[srcCursor] == '.' && BINS[srcCursor+1] == '.'){
      srcCursor += 2;
      return false;
    }
    else{
      assert(false, "error in writing bins at line "~ srcLine.to!string ~ " " ~ BINS[srcCursor]);
    }
  }
  void parseCurlyOpen(){
    if(BINS[srcCursor] != '{'){
      assert(false);
    }
    ++ srcCursor;
  }
  void parseEqual(){
    if(BINS[srcCursor] != '='){
      assert(false);
    }
    ++ srcCursor;
  }
  size_t parseName(){
    auto start = srcCursor;
    while(BINS[srcCursor] != ' ' && BINS[srcCursor] != '=' && BINS[srcCursor] != '\n'&& BINS[srcCursor] != '\t' ){
      ++srcCursor;
    }
    return start;
  }
  BinType parseType(){
    parseSpace();
    if(BINS[srcCursor] == '['){
      srcCursor ++;
      parseSpace();
      if(BINS[srcCursor] == ']'){
	++srcCursor;
	return BinType.DYNAMIC;
      }
      return BinType.STATIC;
    }
    else{
      return BinType.SINGLE;
    }
  }
  size_t parseLiteral() {
    size_t start = srcCursor;
    if(BINS[srcCursor] == '$'){
      ++srcCursor;
      return parseLiteral()-1;
    }
    // check for - sign
    if (BINS[srcCursor] == '-'){
      ++srcCursor;
    }
    // look for 0b or 0x
    if (srcCursor + 2 <= BINS.length &&
	BINS[srcCursor] == '0' &&
	(BINS[srcCursor+1] == 'x' ||
	 BINS[srcCursor+1] == 'X')) { // hex numbers
      srcCursor += 2;
      while (srcCursor < BINS.length) {
	char c = BINS[srcCursor];
	if ((c >= '0' && c <= '9') ||
	    (c >= 'a' && c <= 'f') ||
	    (c >= 'A' && c <= 'F') ||
	    (c == '_')) {
	  ++srcCursor;
	}
	else {
	  break;
	}
      }
    }
    else if (srcCursor + 2 <= BINS.length &&
	     BINS[srcCursor] == '0' &&
	     (BINS[srcCursor+1] == 'b' ||
	      BINS[srcCursor+1] == 'B')) { // binary numbers
      srcCursor += 2;
      while (srcCursor < BINS.length) {
	char c = BINS[srcCursor];
	if ((c == '0' || c == '1' || c == '_')) {
	  ++srcCursor;
	}
	else {
	  break;
	}
      }
    }
    else {			// decimals
      while (srcCursor < BINS.length) {
	char c = BINS[srcCursor];
	if ((c >= '0' && c <= '9') ||
	    (c == '_')) {
	  ++srcCursor;
	}
	else {
	  break;
	}
      }
    }
    if (srcCursor > start) {
      // Look for long/short specifier
      while (srcCursor < BINS.length) {
	char c = BINS[srcCursor];
	if (c == 'L' || c == 'u' ||  c == 'U') {
	  ++srcCursor;
	}
	else {
	  break;
	}
      }
    }
    return start;
  }
  string parseBinDeclaration(){
    if(srcCursor + 4 < BINS.length && BINS[srcCursor] == 'b' && BINS[srcCursor+1] == 'i' && BINS[srcCursor+2] == 'n' && BINS[srcCursor+3] == 's'){
      srcCursor += 4;
      return "";
    }
    else if(srcCursor + 11 < BINS.length && BINS[srcCursor .. srcCursor + 11] == "ignore_bins"){
      srcCursor += 11;
      return "_ig";
    }
    else if(srcCursor + 12 < BINS.length && BINS[srcCursor .. srcCursor + 12] == "illegal_bins"){
      srcCursor += 12;
      return "_ill";
    }
    else
      assert(false, "error in writing bins at line " ~ srcLine.to!string);
    //return start;
  }
  size_t parseSpace() {
    size_t start = srcCursor;
    while (srcCursor < BINS.length) {
      auto srcTag = srcCursor;

      parseLineComment();
      parseBlockComment();
      parseNestedComment();
      parseWhiteSpace();

      if (srcCursor > srcTag) {
	continue;
      }
      else {
	break;
      }
    }
    return start;
  }
  size_t parseComment(){
    auto start = srcCursor;
    while (srcCursor < BINS.length) {
      auto srcTag = srcCursor;
      parseLineComment();
      parseBlockComment();
      parseNestedComment();
      if (srcCursor > srcTag) {
	continue;
      }
      else {
	break;
      }
    }
    return start;
  }
  size_t parseWhiteSpace() {
    auto start = srcCursor;
    while (srcCursor < BINS.length) {
      auto c = BINS[srcCursor];
      // eat up whitespaces
      if (c is '\n') ++srcLine;
      if (c is ' ' || c is '\n' || c is '\t' || c is '\r' || c is '\f') {
	++srcCursor;
	continue;
      }
      else {
	break;
      }
    }
    return start;
  }

  size_t parseLineComment() {
    size_t start = srcCursor;
    if (srcCursor >= BINS.length - 2 ||
	BINS[srcCursor] != '/' || BINS[srcCursor+1] != '/') return start;
    else {
      srcCursor += 2;
      while (srcCursor < BINS.length) {
	if (BINS[srcCursor] == '\n') {
	  break;
	}
	else {
	  if (srcCursor == BINS.length) {
	    // commment unterminated
	    assert (false, "Line comment not terminated at line "~ srcLine.to!string);
	  }
	}
	srcCursor += 1;
      }
      srcCursor += 1;
      return start;
    }
  }

  size_t parseBlockComment() {
    size_t start = srcCursor;
    if (srcCursor >= BINS.length - 2 ||
	BINS[srcCursor] != '/' || BINS[srcCursor+1] != '*') return start;
    else {
      srcCursor += 2;
      while (srcCursor < BINS.length - 1) {
	if (BINS[srcCursor] == '*' && BINS[srcCursor+1] == '/') {
	  break;
	}
	else {
	  if (srcCursor == BINS.length - 1) {
	    // commment unterminated
	    assert (false, "Block comment not terminated at line "~ srcLine.to!string);
	  }
	}
	srcCursor += 1;
      }
      srcCursor += 2;
      return start;
    }
  }
  void parseBin(string BinType){
    size_t srcTag;
    while(true){
      if(BINS[srcCursor] == '['){
	++srcCursor;
	parseSpace();
	srcTag = parseLiteral();
	string min;
	if(BINS[srcTag .. srcCursor] == "$"){
	  min = T.max.stringof;
	}
	else if (BINS[srcTag] == '$'){
	  min = "N["~BINS[srcTag+1 .. srcCursor]~"]";
	}
	else {
	  min = BINS[srcTag .. srcCursor];
	}
	//min = to!T(BINS[srcTag .. srcCursor]);
	parseSpace();
	bool isInclusive = parseRangeType();
	parseSpace();
	srcTag = parseLiteral();
	string max;
	if(BINS[srcTag .. srcCursor] == "$"){
	  max = T.max.stringof;
	}
	else if (BINS[srcTag] == '$'){
	  max = "N["~BINS[srcTag+1 .. srcCursor]~"]";
	}
	else{
	  max = BINS[srcTag .. srcCursor];
	}
	if(!isInclusive){
	  max ~= "-1";
	}
	fill(BinType ~"[$-1].addRange(" ~ min ~ ", " ~ max ~ ");\n");
	parseSpace();
	if(BINS[srcCursor] != ']'){
	  assert(false, "range not ended after two elements at line "~ srcLine.to!string);
	}
	++srcCursor;
	parseSpace();
      }
      else{
	srcTag = parseLiteral();
	string val;
	if(BINS[srcTag .. srcCursor] == "$"){
	  val = T.max.stringof;
	}
	else if (BINS[srcTag] == '$'){
	  val = "N["~BINS[srcTag+1 .. srcCursor]~"]";
	}
	else{
	  val = BINS[srcTag .. srcCursor];
	}
	//makeBins ~= 
	fill(BinType ~ "[$-1].addRange(" ~ val ~ ");\n");
	parseSpace();
      }
      if(BINS[srcCursor] == '}'){
	break;
      }
      parseComma();
    }

  }
  size_t parseNestedComment() {
    size_t nesting = 0;
    size_t start = srcCursor;
    if (srcCursor >= BINS.length - 2 ||
	BINS[srcCursor] != '/' || BINS[srcCursor+1] != '+') return start;
    else {
      srcCursor += 2;
      while (srcCursor < BINS.length - 1) {
	if (BINS[srcCursor] == '/' && BINS[srcCursor+1] == '+') {
	  nesting += 1;
	  srcCursor += 1;
	}
	else if (BINS[srcCursor] == '+' && BINS[srcCursor+1] == '/') {
	  if (nesting == 0) {
	    break;
	  }
	  else {
	    nesting -= 1;
	    srcCursor += 1;
	  }
	}
	srcCursor += 1;
	if (srcCursor >= BINS.length - 1) {
	  // commment unterminated
	  assert (false, "Block comment not terminated at line "~ srcLine.to!string);
	}
      }
      srcCursor += 2;
      return start;
    }
  }

  void parseBinOfType(string type){
    BinType bintype = parseType();
    if(bintype == BinType.SINGLE){
      auto srcTag = parseName();
      string name = BINS[srcTag .. srcCursor];
      parseSpace();
      parseEqual();
      parseSpace();
      parseCurlyOpen();
      parseSpace();
      fill(type ~ "_bins ~= Bin!T( \"" ~ name ~ "\");\n");
      parseBin(type ~ "_bins");
    }
    else if(bintype == BinType.DYNAMIC) {
      parseSpace();
      auto srcTag = parseName();
      if (type == "_ig"){
	fill(type ~ "_bins ~= Bin!T( \"" ~ BINS[srcTag .. srcCursor] ~ "\");\n");	
      }
      else {
	fill(type ~ "_dbins ~= Bin!T( \"" ~ BINS[srcTag .. srcCursor] ~ "\");\n");
      }
      parseSpace();
      parseEqual();
      parseSpace();
      parseCurlyOpen();
      parseSpace();
      if (type == "_ig"){
	parseBin(type ~ "_bins");
      }
      else {
	parseBin(type ~ "_dbins");
      }
    }
    else {
      auto srcTag = parseLiteral();
      string arrSize = BINS[srcTag .. srcCursor];
      parseSpace();
      if(BINS[srcCursor] != ']'){
        assert(false, "error in writing bins at line "~ srcLine.to!string);
      }
      ++srcCursor;
      parseSpace();
      srcTag = parseName();
      if (type == "_ig"){ //no need for arrays in ignore bins
	fill(type ~ "_bins ~= Bin!T( \"" ~ BINS[srcTag .. srcCursor] ~ "\");\n");
	// fill(type ~ "_sbinsNum ~= " ~ arrSize ~ "; \n");
      }
      else {
	fill(type ~ "_sbins ~= Bin!T( \"" ~ BINS[srcTag .. srcCursor] ~ "\");\n");
	fill(type ~ "_sbinsNum ~= " ~ arrSize ~ "; \n");
      }
      parseSpace();
      parseEqual();
      parseSpace();
      parseCurlyOpen();
      parseSpace();
      if (type == "_ig"){
	parseBin(type ~ "_bins");
      }
      else {
	parseBin(type ~ "_sbins");
      }
    }
    ++srcCursor;
    parseSpace();
    if(BINS[srcCursor] != ';'){
      assert(false, "';' expected, not found at line " ~ srcLine.to!string);
    }
    ++srcCursor;
    parseSpace();
  }
  bool isTypeStatement(){
    if (BINS[srcCursor] == 'o' || BINS[srcCursor] == 't'){
      return true;
    }
    return false;
  }
  void fillTillEnd(){
    size_t srcTag = srcCursor;
    while (BINS[srcCursor] != ';'){
      srcCursor ++;
    }
    srcCursor++;
    fill(BINS[srcTag .. srcCursor]);
    fill("\n");
  }
  string parse(){
    parseSpace();
    while(srcCursor < BINS.length){
      if (isTypeStatement()){
	fillTillEnd();
      }
      else {
	string type = parseBinDeclaration();
	parseBinOfType(type);
      }
      parseSpace();
    }
    return outBuffer;
  }
}

// struct BinRange(T)
// {
//   this (T val){
//     _min = val;
//     _max = val;
//   }
//   this (T min, T max){
//     _min = min;
//     _max = max;
//   }
//   T _min;
//   T _max;
// };

struct Bin(T)
{
  string _name;
  uint _hits;
  T [] _ranges;
  this(string name){
    _name = name;
    _hits = 0;
  }
  size_t length (){
    return _ranges.length;
  }
  ref T opIndex(size_t index){
    return _ranges[index];
  }
  // size_t binarySearch(T val){
  //   size_t left = 0, right = _ranges.length - 1, mid = 0;
  //   while (left <= right)
  //     {
  // 	mid = (right + left) / 2;
  // 	if (val == _ranges[mid]._max)
  // 	  break;
  // 	if (val < _ranges[mid]._max){
  // 	  if(mid == 0){
  // 	    break;
  // 	  }
  // 	  right = mid - 1;
  // 	}
  // 	else if (val > _ranges[mid]._max)
  // 	  left = mid + 1;
  //     }
  //   if(_ranges[mid]._max < val){
  //     mid ++;
  //   }
  //   return mid;
  // }
  size_t binarySearch (T val){ // lower_bound, first element greater than or equal to
    
    size_t count = _ranges.length, step;
    size_t first = 0, last = _ranges.length, it;
    while (count > 0){
      it = first;
      step = count / 2;
      it += step;
      if (_ranges[it] < val){
	first = ++it;
	count -= step + 1;
      }
      else {
	count = step;
      }
    }
    return first;
  }
  
  bool checkHit(T val){
    if (val < _ranges[0] || val > _ranges[$-1]){
      return false;
    }
    size_t idx = binarySearch(val);
    if (idx % 2 == 1 || _ranges[idx] == val){
      return true;
    }
    return false;
  }
  void addRange (T val){
    T [] b = [val, val];
    or(b);
  }
  void addRange (T min, T max){
    T [] b = [min, max];
    or(b);
  }
  
  bool fallsIn(T x, T [] a, size_t pos){
    for (size_t i = pos; i < a.length; i++){
      T elem = a[i];
      if (x < elem){
	if (i % 2==0){
	  return false;
	}
	return true;
      }
      if (x == elem){
	return true;
      }
    }
    return false;
  }
  
  void or (Bin!T other){
    or(other._ranges);
  }
  T [] opSlice(){
    return _ranges;
  }
  void slice(size_t start, size_t end){
    assert(start <= end);
    _ranges = _ranges[start .. end];
  }
  void del (size_t n){
    _ranges.length -= n;
  }
  void opOpAssign(string op)(T r) if (op == "~"){
    _ranges ~= r;
  }
  void opOpAssign(string op)(T [] r) if (op == "~"){
    _ranges ~= r;
  }
  size_t opDollar() const @safe nothrow{
    return _ranges.length;
  }
  
  void negateBin(){
    // if (isEmpty()){
    //   T[2] temp = [T.min, T.max];
    //   this ~= temp;
    //   return;   
    // }
    if (_ranges[0] == T.min){
      _ranges = _ranges[1 .. $];
    }
    else {
      this ~= _ranges[$-1];
      for (size_t i = _ranges.length-2; i > 0; --i){
	_ranges[i] = _ranges[i-1];
      }
      _ranges[0] = T.max;
    }
    if (_ranges[$-1] == T.max){
      _ranges.length --;
    }
    else{
      this ~= T.min;
    }
    for (size_t i = 0; i < _ranges.length; ++i){
      if (i % 2 == 0){
	_ranges[i] ++;
      }
      else {
	_ranges[i] --;
      }
    }
    // if (_first == _last){
    //   clear();
    // }
  }
  void or(T [] b){
    size_t a1 = 0;
    size_t b1 = 0;
    size_t len = _ranges.length;
    while (a1 < len || b1 < b.length){
      if (a1 >= len){
	size_t temp = this.length - len;
	if ((temp != 0) && (temp % 2 == 0) && ((this[$-1] == b[b1]-1)||(this[$-1] == b[b1]))){
	  this.del(1);
	  b1 ++;
	}
	while (b1 < b.length){
	  this ~= b[b1];
	  b1++;
	}
	continue;
      }
      else if (b1 >= b.length){
	size_t temp = this.length - len;
	if ((temp != 0) && (temp % 2 == 0) && ((this[$-1] == this[a1]-1)||(this[$-1] == this[a1]))){
	  this.del(1);
	  a1 ++;
	}
	while (a1 < len){
	  this ~= this[a1];
	  a1++;
	}
	continue;
      }
      if (this[a1] < b[b1]){
	if (!fallsIn(this[a1], b, b1)){
	  size_t temp = this.length - len;
	  if ((temp != 0) && (temp % 2 == 0) && ((this[$-1] == this[a1]-1)||(this[$-1] == this[a1]-1))){
	    this.del(1);
	  }
	  else {
	    this ~= this[a1];
	  }
	}
	a1++;
      }
      else if (this[a1] > b[b1]){
	if (!fallsIn(b[b1], this[], a1)){
	  size_t temp = this.length - len;
	  if ((temp != 0) && (temp % 2 == 0) && ((this[$-1] == b[b1] -1)||(this[$-1] == b[b1]))){
	    this.del(1);
	  }
	  else {
	    this ~= b[b1];
	  }
	}
	b1++;
      }
      else {
	if ((a1+b1)%2==0){
	  this ~= this[a1];
	  a1++;
	  b1++;
	}
	else {
	  a1++;
	  b1++;
	}
      }
    }
    this.slice(len, _ranges.length);
  }
  
  void and(T [] b){
    size_t a1 = 0;
    size_t b1 = 0;
    size_t len = _ranges.length;
    while (a1 != len && b1 != b.length){
      if (this[a1] < b[b1]){
	if (fallsIn(this[a1], b, b1)){
	  this ~= this[a1];
	}
	a1++;
      }
      else if (this[a1] > b[b1]){
	if (fallsIn(b[b1], this[], a1)){
	  this ~= b[b1];
	}
	b1++;
      }
      else {
	if ((a1+b1)%2==0){
	  this ~= this[a1];
	  a1++;
	  b1++;
	}
	else {
	  this ~= this[a1];
	  this ~= this[a1];
	  a1++;
	  b1++;
	}
      }
    }
    this.slice(len, _ranges.length);
  }
  // void addRange(T val)
  // {
  //   if(_ranges.length == 0){
  //     _ranges ~= BinRange!T(val);
  //   }
  //   auto pos = binarySearch(val);
  //   if(pos >= _ranges.length){
  //     _ranges ~= BinRange!T(val);
  //     return;
  //   }
  //   if(_ranges[pos]._min <= val){
  //     return;
  //   }
  //   _ranges = _ranges[0 .. pos] ~ BinRange!T(val) ~ _ranges[pos .. $];
  // }
  string getName(){
    return _name;    
  }
  auto getRanges(){
    return _ranges;
  }

  // void addRange(T min, T max)
  // {
  //   assert(min <= max, "minimum value is greater than maximum in range");
  //   if(_ranges.length == 0){
  //     _ranges ~= BinRange!T(min, max);
  //   }
  //   auto pos1 = binarySearch(min);
  //   if(pos1 >= _ranges.length){
  //     _ranges ~= BinRange!T(min, max);
  //     return;
  //   }
  //   auto pos2 = binarySearch(max);
  //   if(_ranges[pos1]._min <= min){
  //     if(pos2 >= _ranges.length){
  //       auto temp = BinRange!T(_ranges[pos1]._min, max);
  //       _ranges.length = pos1;
  //       _ranges ~= temp;
  //     }
  //     else{
  //       if(pos1 == pos2){
  //         return;
  //       }
  //       if(_ranges[pos2]._min <= max){
  //         auto temp = BinRange!T(_ranges[pos1]._min, _ranges[pos2]._max);
  //         _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2+1 .. $];
  //       }
  //       else{
  //         auto temp = BinRange!T(_ranges[pos1]._min, max);
  //         _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2 .. $];
  //       }
  //     }
  //   }
  //   else{
  //     if(pos2 >= _ranges.length){
  //       auto temp = BinRange!T(min, max);
  //       _ranges.length = pos1;
  //       _ranges ~= temp;
  //     }
  //     else{
  //       if(_ranges[pos2]._min <= max){
  //         auto temp = BinRange!T(min, _ranges[pos2]._max);
  //         _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2+1 .. $];
  //       }
  //       else{
  //         auto temp = BinRange!T(min, max);
  //         _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2 .. $];
  //       }
  //     }
  //   }
  // }
  // void negateBin(){
  //   bool firstMin = _ranges[0]._min == T.min;
  //   auto replace = BinRange!T(T.min, _ranges[0]._min-1);
  //   for (int i = 0; i < _ranges.length-1; i ++){
  //     auto newReplace = BinRange!T(_ranges[i]._max+1, _ranges[i+1]._min-1);
  //     _ranges[i] = replace;
  //     replace = newReplace;
  //   }
  //   if (_ranges[$-1]._max == T.max){
  //     _ranges[$-1] = replace;
  //   }
  //   else {
  //     _ranges ~= BinRange!T(_rangs[$-1].max+1, T.max);
  //     ranges[$-2] = replace;
  //   }
  //   if (firstMin){
  //     _ranges = _ranges[1 .. $];
  //   }
  // }
  
  string describe()
  {
    import std.conv;
    string s = "Name : " ~ _name ~ "\n";
    /* if(_type == Type.SINGLE){ */
    /*     s ~= "Single : \n"; */
    /*     return (s ~ to!string(_single) ~ "\n"); */
    /* } */
    /* s ~= "Multiple : \n"; */
    foreach (elem; _ranges)
      {
	s ~= to!string(elem) ~ ", ";
      }
    s ~= "\n";
    return s;
  }
  size_t count(){
    size_t c = 0;
    for(size_t i = 0; i < _ranges.length - 1; i += 2){
      c += (1uL + _ranges[i+1]) - _ranges[i];
    }
    return c;
  }
  // void normalize(){
  //   for(size_t i = 0; i < _ranges.length-1; i++){
  //     assert(_ranges[i]._max < _ranges[i+1]._min && _ranges[i]._max >= _ranges[i]._min);
  //     if(_ranges[i]._max == _ranges[i+1]._min - 1){
  //       _ranges[i]._max = _ranges[i+1]._max;
  //       if(i+2 < _ranges.length){
  //         _ranges = _ranges[0 .. i+1] ~ _ranges[i+2 .. $];
  //       }
  //       else{
  //         _ranges = _ranges[0 .. i+1];
  //       }
  //     }
  //   }
  // }
  // bool checkHit(T val)
  // {
  //   /* if(_type == Type.SINGLE){ */
  //   /*     return (val == _single); */
  //   /* } */
  //   ulong len = _ranges.length;
  //   if (val < _ranges[0]._min)
  //     return false;
  //   if (val > _ranges[$ - 1]._max)
  //     return false;
  //   ulong left = 0, right = len - 1;
  //   while (left <= right)
  //     {
  // 	ulong mid = (right + left) / 2;
  // 	if (val >= _ranges[mid]._min && val <= _ranges[mid]._max)
  // 	  return true;
  // 	if (val < _ranges[mid]._min)
  // 	  right = mid - 1;
  // 	else if (val > _ranges[mid]._max)
  // 	  left = mid + 1;
  //     }
  //   return false;
  // }
}

// interface:  

interface coverInterface {
  void sample ();
  double get_coverage();
  double get_inst_coverage();
  void start();
  void stop();
  bool [] get_inst_hits();
  size_t get_weight();
  bool isCross();
  //double query();
  //double inst_query();
}

// cross stuff: 

string makeArray(size_t len, string type,string name){
  string s = type ~ " ";
  for(int i = 0; i < len; i++){
    s ~= "[]"; 
  }
  s ~= " " ~ name ~ ";";
  return s;
}

string crossSampleHelper(int n){
  import std.conv;
  string s = "bool [][] inst_hits_arr;\n";
  for(int i = 0; i < n; i++){
    s ~= "inst_hits_arr ~= coverPoints[" ~ i.to!string() ~ "].get_inst_hits();\n";
  }
  for(int i = 0; i < n; i++){
    s ~= "foreach(i_" ~ i.to!string() ~ ", is_hit_" ~ i.to!string() ~ "; inst_hits_arr[" ~ i.to!string() ~ "]){\n";
    s ~= "if(!is_hit_" ~ i.to!string() ~ ")\ncontinue;\n";
  }
  s ~= "_hits";
  for(int i = 0; i < n; i++){
    s ~= "[i_" ~ i.to!string() ~ "]"; 
  }
  s ~= "++;\n";
  s ~= "_inst_hits";
  for(int i = 0; i < n; i++){
    s ~= "[i_" ~ i.to!string() ~ "]"; 
  }
  s ~= " = true;\n";
  for(int i = 0; i < n; i++)
    s ~= "}\n";
  return s;
}

string arrayInitialising(string name, int n){
  import std.conv;
  string s,tmp = name;
  s ~= name ~ ".length = bincnts[0];\n";
  for(int i = 0; i < n; i++){
    s ~= "for(int i_" ~ (i).to!string() ~ " = 0; i_" ~ (i).to!string() ~ " < bincnts[" ~ (i).to!string() ~ "]; i_" ~ (i).to!string() ~ "++){\n";
    tmp ~= "[i_" ~ (i).to!string() ~ "]";
    if(i < n - 1)
      s ~= tmp ~ ".length = bincnts[" ~ (i + 1).to!string() ~"];\n";
    else 
      s ~= tmp ~ "= 0;\n";
  }
  for(int i = 0; i < n; i++)
    s ~= "}\n";
  return s;
}

string sampleCoverpoints(int n){
  import std.conv;
  string s;
  for(int i = 0; i < n; i++){
    s ~= "if (isIntegral!(typeof(N[" ~ i.to!string() ~ "])))";
    s ~= "coverPoints[" ~ i.to!string() ~ "].sample();\n";
  }
  return s;
}


// struct Cross ( N... ){
//   coverInterface innerClass;
//   void Initialize(){
//     if(innerClass is null)
//       innerClass = new CrossClass!( N )();
//   }
//   void sample(){
//     Initialize();
//     innerClass.sample();
//   }
//   double get_coverage(){
//     Initialize();
//     return innerClass.get_coverage();
//   }
//   double get_inst_coverage(){
//     Initialize();
//     return innerClass.get_inst_coverage();
//   }
//   void start(){
//     Initialize();
//     innerClass.start();
//   }
//   void stop(){
//     Initialize();
//     innerClass.stop();
//   }
//   auto get_cross_inst_hits(){
//     Initialize();
//     return (cast(CrossClass!(N))(innerClass)).get_cross_inst_hits();
//   }
//   size_t get_weight(){
//     Initialize();
//     return innerClass.get_weight();
//   }
//   bool isCross(){
//     return true;
//   }
// }

class Cross ( N... ): coverInterface{
  import std.traits: isIntegral;
  enum size_t len = N.length;
  ulong [] bincnts;
  mixin(makeArray(len, "uint", "_hits"));
  mixin(makeArray(len, "bool", "_inst_hits"));
  coverInterface [] coverPoints;
  this (){
    foreach (i , ref elem; N){
      static if (!(isIntegral!(typeof(elem)))){
        // elem.Initialize();
        coverPoints ~= elem;
        bincnts ~= elem.getBins().length;
      }
      else {
        auto tmp = new CoverPoint!(elem)();
        coverPoints ~= tmp;
        bincnts ~= tmp.getBins().length;
      }
    }
    mixin(arrayInitialising("_hits", len));
    mixin(arrayInitialising("_inst_hits", len));
  }
  override void sample(){
    mixin(arrayInitialising("_inst_hits", len));
    mixin(sampleCoverpoints(len));
    mixin(crossSampleHelper(N.length));
  }
  override double get_coverage(){
    return 0;

  }
  override double get_inst_coverage(){
    return 0;

  }
  override void start(){

  }
  override void stop(){

  }
  override bool [] get_inst_hits(){
    assert(false);
  }
  auto get_cross_inst_hits(){
    return _inst_hits;
  }
  override size_t get_weight(){
    return 1;
  }
  override bool isCross(){
    return true;
  }
}


// struct CoverPoint (string BINS="", T){
//   coverInterface innerClass;
//   this (ref T t){
//     innerClass = new CoverPointClass!(BINS)(t);
//   }
//   auto getBins() {
//     return (cast(CoverPointClass!(t, BINS))(innerClass)).getBins();
//   }
//   string describe(){
//     return (cast(CoverPointClass!(t, BINS))(innerClass)).describe();
//   }
//   void sample(){
//     innerClass.sample();
//   }
//   double get_coverage(){
//     return innerClass.get_coverage();
//   }
//   double get_inst_coverage(){
//     return innerClass.get_inst_coverage();
//   }
//   void start(){
//     innerClass.start();
//   }
//   void stop(){
//     innerClass.stop();
//   }
//   bool [] get_inst_hits(){
//     return innerClass.get_inst_hits();
//   }
//   size_t get_weight(){
//     return innerClass.get_weight();
//   }
//   bool isCross(){
//     return false;
//   }
// }

struct Parameters {
  size_t weight = 1;
  size_t goal = 90;
  size_t at_least = 1;
  size_t auto_bin_max = 64;
  size_t corss_auto_bin_max = size_t.max;
  string comment = "";
}
struct StaticParameters {
  size_t weight = 1;
  size_t goal = 90;
  string comment = "";
}

class CoverPoint(alias t, string BINS="", N...) : coverInterface{
  import std.traits: isIntegral;
  // import esdl.data.bvec: isBitVector;
  // static assert(isIntegral!T || isBitVector!T || is(T: bool),
  //     "Only integral, bitvec, or bool values can be covered."
  //     ~ " Unable to cover a value of type: " ~ T.stringof);
  // T* _point; // = &t;
  //char[] outBuffer;
  alias T = typeof(t);
  string outBuffer;
  bool [] _inst_hits;
  size_t _num_hits;
  size_t _num_inst_hits;
  Parameters option;
  static StaticParameters type_option;
  this (){

    // import std.stdio;
    static if (BINS != ""){
      mixin(doParse!T(BINS));
    }
    else {
      import std.conv;
      mixin(doParse!T("bins [64] a = {[" ~ T.min.to!string() ~ ":" ~ T.max.to!string() ~ "]};"));
    }
    // writeln(doParse!T(BINS));

    procDyanamicBins(_bins,_dbins);
    // procDyanamicBins(_ig_bins,_ig_dbins);
    procDyanamicBins(_ill_bins,_ill_dbins);
    procStaticBins(_bins,_sbins,_sbinsNum);
    // procStaticBins(_ig_bins,_ig_sbins,_ig_sbinsNum);
    procStaticBins(_ill_bins,_ill_sbins,_ill_sbinsNum);
    procIgnoreBins();
    _inst_hits.length = _bins.length; 
  }
  // the number of bins and which one is hit is made out by the
  // sample function
  size_t [] _sbinsNum;
  size_t [] _ig_sbinsNum;
  size_t [] _ill_sbinsNum;
  Bin!(T)[] _bins;
  Bin!(T)[] _sbins;
  Bin!(T)[] _dbins;
  Bin!(T)[] _ig_bins;
  // Bin!(T)[] _ig_sbins;
  // Bin!(T)[] _ig_dbins;
  Bin!(T)[] _ill_bins;
  Bin!(T)[] _ill_sbins;
  Bin!(T)[] _ill_dbins;
  uint _defaultCount;
  // We keep a count of how many times a bin is hit
  int _pos;	     // position of t the covergoup; -1 otherwise
  // void _initPoint(G)(G g) {
  //   auto _outer = g.outer;
  //   assert (_outer !is null);
  //   static if (__traits(hasMember, g, t.stringof)) {
  //     _point = &(__traits(getMember, g, t.stringof));
  //     assert(_point !is null);
  //   }
  //   else static if (__traits(hasMember, g.outer, t.stringof)) {
  //     _point = &(__traits(getMember, _outer, t.stringof));
  //     assert(_point !is null);
  //   }
  //   else {
  //     _point = &(t);
  //     assert(_point !is null);
  //   }
  //   static if (isIntegral!T) {
  //     _bins.length = 64;
  //   }
  //   else static if (is(T == bool)) {
  //     _bins.length = 2;
  //   }
  //   else {
  //     static if (T.SIZE > 6) {
  //       _bins.length = 64;
  //     }
  //     else {
  //       _bins.length = T.max - T.min;
  //     }
  //   }
  // }


  auto getBins() {
    return _bins;
  }
  
  // import std.stdio;

  import std.conv;
  void procIgnoreBins(){
    if (_ig_bins.length == 0){
      return;
    }
    while (_ig_bins.length > 1){
      _ig_bins[$-2].or(_ig_bins[$-1]);
      _ig_bins.length --;
    }
    _ig_bins[0].negateBin();
    foreach (ref bin; _bins){
      bin.and(_ig_bins[0][]);
    }
  }
  void procDyanamicBins(ref Bin!(T) [] alias_bins, ref Bin!(T) [] alias_dbins){
    foreach(tempBin; alias_dbins ){
      auto ranges = tempBin.getRanges();
      size_t num = 0;
      for(size_t i = 0; i < ranges.length-1; i += 2){
        for(T j = ranges[i]; j <= ranges[i+1]; j++){
          string tempname = tempBin.getName ~ "[" ~ to!string(num) ~ "]";
          alias_bins ~= Bin!T(tempname); 
          alias_bins[$ - 1].addRange(j);
          ++num;
        }
      }
    }
    alias_dbins.length = 0;
  }
  void procStaticBins(ref Bin!(T) [] alias_bins, ref Bin!(T) [] alias_sbins, ref size_t [] alias_sbinsNum){
    foreach(index, tempBin; alias_sbins){
      size_t count = tempBin.count();
      auto ranges = tempBin.getRanges();
      size_t arrSize = alias_sbinsNum[index];
      T Binsize = to!(T)(count / arrSize);
      T rem = to!(T)(count % arrSize);
      size_t binNum = 0;
      T binleft = Binsize;
      for(size_t i = 0; i < arrSize; i++){
        alias_bins ~= Bin!T(tempBin.getName ~ "[" ~ to!string(i) ~ "]");
      }
      if(Binsize == 0){
        assert(false, "array size created more than the number of elements in the array");
      }
      for(size_t i = 0; i < ranges.length-1; i+=2){
        if(binleft == 0){
    	  binNum ++;
    	  assert(binNum < arrSize);
    	  if(binNum == arrSize - rem){
    	    Binsize ++;
    	  }
    	  binleft = Binsize;
    	}
        size_t rangeCount = size_t(ranges[i+1]) - size_t(ranges[i]) + 1;
        if(rangeCount > binleft){
          //makeBins ~= 

          alias_bins[$ - (arrSize - binNum)].addRange((ranges[i]), (ranges[i] + binleft - 1));
          ranges[i] += binleft;
          binleft = 0;
          i -= 2;
        }
        else{
          //makeBins ~= 

          alias_bins[$ - (arrSize - binNum)].addRange((ranges[i]),  (ranges[i+1]));
          binleft -= rangeCount;
        }
      }
    }
    alias_sbins.length = 0;
    alias_sbinsNum.length = 0;
  }
  string describe(){
    string s = "";
    foreach(bin; _bins){
      s ~= bin.describe();
    }
    s ~= "\n";
    return s;
  }
  override void sample(){
    // writeln("sampleCalled");
    _num_inst_hits = 0;
    foreach(i, ref bin;_bins){
      _inst_hits[i] = false;
      if(bin.checkHit(t)){
	if (bin._hits == 0){
	  _num_hits ++;
	}
        bin._hits++;
        _inst_hits[i] = true;
	_num_inst_hits ++;
      }
    } 
  }
  override double get_coverage(){
    return cast(double)(_num_hits)/_bins.length;
  }
  override double get_inst_coverage(){
    return cast(double)(_num_inst_hits)/_bins.length;
  }
  override void start(){

  }
  override void stop(){

  }
  override bool [] get_inst_hits(){
    return _inst_hits;
  }
  override size_t get_weight(){
    return 1;
  }
  override bool isCross(){
    return false;
  }
}

/*class CoverGroup: rand.disable {		// Base Class
  bool _isInitialized;		// true if the CoverGroup has been initialized
  }*/

// private void initialize(G, int I=0)(G g) if (is(G: CoverGroup)) {
//   static if (I == 0) {
//     if (g._isInitialized) return;
//     else g._isInitialized = true;
//   }
//   static if (I >= G.tupleof.length) {
//     return;
//   }
//   else {
//     alias E = typeof(g.tupleof[I]);
//     static if (is (E: CoverPointClass!(t, S), alias t, string S)) {
//       g.tupleof[I]._initPoint(g);
//       int index = findElementIndex!(t.stringof, G);
//       g.tupleof[I]._initPos(index);
//     }
//     initialize!(G, I+1)(g);
//   }
// }

// private void samplePoints(int I, int N, G)(G g) if (is(G: CoverGroup)) {
//   static if (I >= G.tupleof.length) {
//     return;
//   }
//   else {
//     alias E = typeof(g.tupleof[I]);
//     static if (is (E: CoverPointClass!(t, S), alias t, string S)) {
//       g.tupleof[I].sample(N);
//     }
//     samplePoints!(I+1, N)(g);
//   }
// }


// public void sample(G, V...)(G g, V v) if (is(G: CoverGroup)) {
//   // navigate through the class elements of G to know the CoverPointClass
//   // instantiations as well as any Integral/BitVector instances
//   sampleArgs!(0)(g, v);
//   initialize(g);
//   // Now look for all the coverpoints
//   samplePoints!(0, V.length)(g);
// }

// private void sampleArgs(int I, G, V...)(G g, V v) {
//   import std.traits: isAssignable;
//   static if (V.length == 0) {
//     return;
//   }
//   else {
//     alias VAL_TUPLE = getIntElements!G;
//     alias N = VAL_TUPLE[I];
//     static assert (isAssignable!(typeof(G.tupleof[N]), V[0]),
//         "Method sample called with argument of type " ~
//         V[0].stringof ~ " at position " ~ I.stringof ~
//         " is not assignable to type " ~
//         typeof(G.tupleof[N]).stringof);
//     static if (I == 0) {
//       static assert (VAL_TUPLE.length >= V.length,
//           "Method sample called with " ~ V.length.stringof ~
//           " arguments, while it can take only " ~
//           VAL_TUPLE.length.stringof ~
//           " arguments for covergroup of type: " ~ G.stringof);
//     }
//     g.tupleof[N] = v[0];
//     sampleArgs!(I+1)(g, v[1..$]);
//   }
// }

// // return a tuple of integral elements
// private template getIntElements(G, int N=0, I...) {
//   import std.traits: isIntegral;
//   import esdl.data.bvec: isBitVector;
//   static if (N == G.tupleof.length) {
//     enum getIntElements = I;
//   }
//   else {
//     alias T = typeof(G.tupleof[N]);
//     static if (isBitVector!T || isIntegral!T || is(T == bool)) {
//       enum getIntElements = getIntElements!(G, N+1, I, N);
//     }
//     else {
//       enum getIntElements = getIntElements!(G, N+1, I);
//     }
//   }
// }

// private template findElementIndex(string E, G, int I=0, int N=0) {
//   import std.traits: isIntegral;
//   import esdl.data.bvec: isBitVector;
//   static if(I >= G.tupleof.length) {
//     enum findElementIndex = -1;
//   } else {
//     alias T = typeof(G.tupleof[I]);
//     static if (isBitVector!T || isIntegral!T || is(T == bool)) {
//       static if (E == G.tupleof[I].stringof) {
//         enum findElementIndex = N;
//       }
//       else {
//         enum findElementIndex =  findElementIndex!(E, G, I+1, N+1);
//       }
//     }
//     else {
//       enum findElementIndex = findElementIndex!(E, G, I+1, N);
//     }
//   }
// }

// private template nthIntElement(alias g, int N, int I=0) {
//   import std.traits: isIntegral;
//   import esdl.data.bvec: isBitVector;
//   static assert(I < g.tupleof.length);
//   alias T = typeof(g.tupleof[I]);
//   static if (isBitVector!T || isIntegral!T || is(T == bool)) {
//     static if (N == 0) {
//       enum nthIntElement = g.tupleof[I];
//     }
//     else {
//       enum nthIntElement = nthIntElement!(g, N-1, I+1);
//     }
//   }
//   else {
//     enum nthIntElement = nthIntElement!(g, N, I+1);
//   }
// }

// private template countIntElements(G, int COUNT=0, int I=0) {
//   import std.traits: isIntegral;
//   import esdl.data.bvec: isBitVector;
//   static if (I != G.tupleof.length) {
//     alias T = typeof(G.tupleof[I]);
//     static if (isBitVector!T || isIntegral!T || is(T == bool)) {
//       enum countIntElements = countIntElements!(G, COUNT+1, I+1);
//     }
//     else {
//       enum countIntElements = countIntElements!(G, COUNT, I+1);
//     }
//   }
//   else {
//     enum countIntElements = COUNT;
//   }
// }
void main (){
}
unittest {
  int p;
  auto x = new CoverPoint!(p, q{
      bins a = {     1 , 2 }  ;

    })();
  import std.stdio;
  writeln(x.describe()); 
  //x.print();
  //import std.stdio;
  //writeln(x.describe());
}
// unittest {
//   int p;
//   auto x = new CoverPointClass!(q{
//       bins a = { [0:63],65 };
//       bins [] b = { [127:130],[137:147],200,[100:108] }; // note overlapping values
//       bins [3]c = { 200,201,202,204 };
//       bins d = { [1000:$] };
//       bins e = { 125 };
//       //bins [] others = { 1927, 1298 , 2137, [12: 1000]};
//     })(p);
//   import std.stdio;
//   /* writeln(x.describe()); */
//   //import std.stdio;
//   //writeln(x.describe());
// }
unittest {
  int p;
  auto x = new CoverPoint!(p, q{
      bins a = { [0:63],65 };
      bins [] b = { [127:130],[137:147],200,[100:108] }; // note overlapping values
      bins [3]c = { 200,201,202,204 };
      bins d = { [1000:$] };
      bins e = { 125 };
      ignore_bins []a = { 5 , [20:30] };
      ignore_bins [3]b = { [100:104] };
      //bins [] others = { 1927, 1298 , 2137, [12: 1000]};
    })();
  import std.stdio;
  writeln(x.describe()); 
  //import std.stdio;
  //writeln(x.describe());
}
// unittest {
//   int p;
//   auto x = new CoverPointClass!(q{
//       bins [32] a = {[-2147483648:2147483647]};
//     })(p);
//   import std.stdio;
//   writeln(x.describe());
// }
unittest {
  int p;
  auto x = new CoverPoint!(p, q{
      bins [32] a = {[-2147483647:2147483647]};
    })();
  import std.stdio;
  writeln(x.describe());
}
unittest{
  int a = 5, d = 3;
  auto cp = new CoverPoint!(d, q{
      bins [2] a = {2,3};
      option.weight = 4;
    })();
  auto cp2 = new CoverPoint!(a, q{
      bins [] cp2 = {4,5};
    })();
  auto x = new Cross!(cp, cp2)();
  import std.stdio;
  writeln(cp.option.weight);
  /* writeln(cp.describe()); */
  /* writeln(cp2.describe()); */
  cp.sample();
  cp2.sample();
  x.sample();
  auto tmp = x.get_cross_inst_hits();
  assert(tmp[1][1] && !tmp[0][0] && !tmp[0][1] && !tmp[1][0]);

  a = 4;
  cp.sample();
  cp2.sample();
  x.sample();
  tmp = x.get_cross_inst_hits();
  assert(tmp[1][0] && !tmp[0][0] && !tmp[0][1] && !tmp[1][1]);

  d = 2;
  cp.sample();
  cp2.sample();
  x.sample();
  tmp = x.get_cross_inst_hits();
  assert(!tmp[1][0] && tmp[0][0] && !tmp[0][1] && !tmp[1][1]);
  // sampling works
}
// unittest{
//   int a = 5, d = 3;
//   auto cp = CoverPoint!(d,q{
//       bins [2] a = {2,3};
//     })();
//   auto cp2 = CoverPoint!(a,q{
//       bins [] cp2 = {4,5};
//     })();
//   auto x = new CrossClass!(cp,cp2)();
//   /* writeln(cp.describe()); */
//   /* writeln(cp2.describe()); */
//   cp.sample();
//   cp2.sample();
//   x.sample();
//   auto tmp = x.get_cross_inst_hits();
//   assert(tmp[1][1] && !tmp[0][0] && !tmp[0][1] && !tmp[1][0]);

//   a = 4;
//   cp.sample();
//   cp2.sample();
//   x.sample();
//   tmp = x.get_cross_inst_hits();
//   assert(tmp[1][0] && !tmp[0][0] && !tmp[0][1] && !tmp[1][1]);

//   d = 2;
//   cp.sample();
//   cp2.sample();
//   x.sample();
//   tmp = x.get_cross_inst_hits();
//   assert(!tmp[1][0] && tmp[0][0] && !tmp[0][1] && !tmp[1][1]);
//   // sampling works
// }

unittest{
  int a = 1, b = 2;
  auto x = new CoverPoint!(a, q{
      bins x1 = {1,2,3};
      bins x2 = {1};
    })();

  
  auto xb = new Cross!(x,b)();
  x.sample();
  xb.sample();
  // bug in default bin generation 
  /* assert(); */
}
unittest {
  int a;
  auto x = new CoverPoint!(a, q{
      bins a = {1 , 4 , $0}  ;

    }, 3)();
  import std.stdio;
  writeln(x.describe());
}

// unittest {
//   Bin!int a = Bin!int();
//   a.addRange(1, 10);
//   a.addRange(15, 20);
//   import std.stdio;
//   writeln(a.describe(), " ", a.count());
//   a.addRange(11, 14);
//   writeln(a.describe());
// }
