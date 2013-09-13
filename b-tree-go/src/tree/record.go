package tree

type Record struct {
	key   []byte
	value []byte
}

type RecordBulk struct {
	records []*Record
}

func NewRecordBulk() *RecordBulk {
	rb := new(RecordBulk)
	rb.records = make([]*Record, 0, 4)
	return rb
}

func (rb *RecordBulk) Len() int {
	return len(rb.records)
}
