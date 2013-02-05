"use strict"

function CurencyValueClass(str) {
  var value = parseFloat(str.split(" ")[0]);
  var cur = str.split(" ")[1];
  this.get_value = function() { return value; },
  this.get_cur = function() { return cur; },
  this.get_norm_value = function() {
    return this.get_value() * parseFloat(exch_table[this.get_cur()]);
  },
  this.compare = function(cur) {
    var x = this.get_norm_value();
    var y = cur.get_norm_value();
    return value_compare(x, y);
  }
};

function get_cur_value(str) {
  var x = str.replace( /^ *([-0-9,]+) *<div [^>]*class="tooltip"[^>]*>.*<span .*<span [^>]*> *[-0-9, ]+([^ <]+) *<\/span>.*$/, "$1 $2");
  alert(x);
  x = x.replace(/,/, "");
  return new CurencyValueClass(x);
}

function get_value(str) {
  return parseFloat(str.replace(/ *< *div *class *= *"tooltip" *>.*$|,/g, ""));
}

function value_compare(x, y) {
  return (x < y || isNaN(y) ) ? -1 : ((x > y || isNaN(x)) ? 1 : 0);
}

//sets up numeric sorting with ignoring of tooltip's content (first columns)
jQuery.fn.dataTableExt.oSort['num-html-asc'] = function(a, b) {
  var x = get_value(a);
  var y = get_value(b);
  return value_compare(x, y);
};

jQuery.fn.dataTableExt.oSort['num-html-desc'] = function(a, b) {
  var x = get_value(a);
  var y = get_value(b);
  return value_compare(y, x);
};

// sets up numeric sorting based on currency normalizing (all collaborators columns)
jQuery.fn.dataTableExt.oSort['xch-html-asc'] = function(a, b) {
  var x = get_cur_value(a);
  var y = get_cur_value(b);
  alert("" + x.get_value() + " " + x.get_cur() + " ~~ " + x.get_value() + " " + x.get_cur());
  return x.compare(y);
};

jQuery.fn.dataTableExt.oSort['xch-html-desc'] = function(a, b) {
  var x = get_cur_value(a);
  var y = get_cur_value(b);
  alert("" + x.get_value() + " " + x.get_cur() + " ~~ " + x.get_value() + " " + x.get_cur());
  return y.compare(x);
};
    
//sets up numeric sorting based on currency normalizing (last column)
jQuery.fn.dataTableExt.oSort['xch-asc'] = function(a, b) {
  var x = new CurencyValueClass(a);
  var y = new CurencyValueClass(b);
  return x.compare(y);
};

jQuery.fn.dataTableExt.oSort['xch-desc'] = function(a, b) {
  var x = new CurencyValueClass(a);
  var y = new CurencyValueClass(b);
  return y.compare(x);
};
