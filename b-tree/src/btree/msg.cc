#include <algorithm>
#include "msg.h"

using namespace ndb;
using namespace std;

bool MsgBuffer::write(Msg &msg) {
  Iterator iter = lower_bound(_container.begin(), _container.end(), msg._key, MsgCompare(_comparator));
  if(_comparator->compare((*iter)._key, msg._key) != 0) {
    _container.push_back(msg);
  } else {
    (*iter)._value.destroy();

    (*iter)._value = msg._value;
  }
  return true;
}