package tree

import (
	"fmt"
)

type Record struct {
	key   []byte
	value []byte
}

func (r *Record) String() string {
	return fmt.Sprintf("%d:..", r.key[0])
}

type RecordBulk struct {
	records []*Record
}

func NewRecordBulk() *RecordBulk {
	rb := new(RecordBulk)
	rb.records = make([]*Record, 0, 4)
	return rb
}

func (rb *RecordBulk) split(to *RecordBulk) (key []byte) {
	l := rb.Len()
	mid := l / 2
	to.records = append(to.records, rb.records[mid:]...)
	rb.records = rb.records[:mid]
	return to.records[0].key
}

func (rb *RecordBulk) Len() int {
	return len(rb.records)
}
