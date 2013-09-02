package tree

type Record struct {
  key []byte
  value []byte
}


type RecordBulk struct {
  records []*Record
}

