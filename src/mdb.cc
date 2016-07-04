/*
 * Copyright (c) 2015-2016 Carnegie Mellon University.
 *
 * All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. See the AUTHORS file for names of contributors.
 */

#include "pdlfs-common/mdb.h"
#include "pdlfs-common/dcntl.h"
#include "pdlfs-common/gigaplus.h"

namespace pdlfs {

MDBOptions::MDBOptions() : verify_checksums(false), sync(false), db(NULL) {}

MDB::~MDB() {}

Status MDB::GetIdx(const DirId& id, DirIndex* idx, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirIdxType);
#else
  Key key(id.reg, id.snap, id.ino, kDirIdxType);
#endif
  std::string tmp;
  ReadOptions options;
  options.verify_checksums = options_.verify_checksums;
  if (tx != NULL) {
    options.snapshot = tx->snap;
  }
  s = db_->Get(options, key.prefix(), &tmp);
  if (s.ok()) {
    if (!idx->Update(tmp)) {
      s = Status::Corruption(Slice());
    }
  }
  return s;
}

Status MDB::GetInfo(const DirId& id, DirInfo* info, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirMetaType);
#else
  Key key(id.reg, id.snap, id.ino, kDirMetaType);
#endif
  char tmp[20];
  ReadOptions options;
  options.verify_checksums = options_.verify_checksums;
  if (tx != NULL) {
    options.snapshot = tx->snap;
  }
  Slice result;
  s = db_->Get(options, key.prefix(), &result, tmp, sizeof(tmp));
  if (s.ok()) {
    if (!info->DecodeFrom(&result)) {
      s = Status::Corruption(Slice());
    }
  }
  return s;
}

Status MDB::GetNode(const DirId& id, const Slice& hash, Stat* stat, Slice* name,
                    Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirEntType);
#else
  Key key(id.reg, id.snap, id.ino, kDirEntType);
#endif
  key.SetHash(hash);
  std::string tmp;
  ReadOptions options;
  options.verify_checksums = options_.verify_checksums;
  if (tx != NULL) {
    options.snapshot = tx->snap;
  }
  s = db_->Get(options, key.Encode(), &tmp);
  if (s.ok()) {
    Slice input(tmp);
    if (!stat->DecodeFrom(&input)) {
      s = Status::Corruption(Slice());
    } else if (!GetLengthPrefixedSlice(&input, name)) {
      s = Status::Corruption(Slice());
    }
  }
  return s;
}

Status MDB::SetIdx(const DirId& id, const DirIndex& idx, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirIdxType);
#else
  Key key(id.reg, id.snap, id.ino, kDirIdxType);
#endif
  Slice encoding = idx.Encode();
  if (tx == NULL) {
    WriteOptions options;
    options.sync = options_.sync;
    s = db_->Put(options, key.prefix(), encoding);
  } else {
    tx->batch.Put(key.prefix(), encoding);
  }
  return s;
}

Status MDB::SetInfo(const DirId& id, const DirInfo& info, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirMetaType);
#else
  Key key(id.reg, id.snap, id.ino, kDirMetaType);
#endif
  char tmp[20];
  Slice encoding = info.EncodeTo(tmp);
  if (tx == NULL) {
    WriteOptions options;
    options.sync = options_.sync;
    s = db_->Put(options, key.prefix(), encoding);
  } else {
    tx->batch.Put(key.prefix(), encoding);
  }
  return s;
}

Status MDB::SetNode(const DirId& id, const Slice& hash, const Stat& stat,
                    const Slice& name, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirEntType);
#else
  Key key(id.reg, id.snap, id.ino, kDirEntType);
#endif
  key.SetHash(hash);
  Slice value;
  char tmp[200];
  std::string buf;
  Slice encoding = stat.EncodeTo(tmp);
  if (name.size() < sizeof(tmp) - encoding.size() - 5) {
    char* begin = tmp;
    char* end = begin + encoding.size();
    end = EncodeLengthPrefixedSlice(end, name);
    value = Slice(begin, end - begin);
  } else {
    buf.append(encoding.data(), encoding.size());
    PutLengthPrefixedSlice(&buf, name);
    value = Slice(buf);
  }
  if (tx == NULL) {
    WriteOptions options;
    options.sync = options_.sync;
    s = db_->Put(options, key.Encode(), value);
  } else {
    tx->batch.Put(key.Encode(), value);
  }
  return s;
}

Status MDB::DelIdx(const DirId& id, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirIdxType);
#else
  Key key(id.reg, id.snap, id.ino, kDirIdxType);
#endif
  if (tx == NULL) {
    WriteOptions options;
    options.sync = options_.sync;
    s = db_->Delete(options, key.prefix());
  } else {
    tx->batch.Delete(key.prefix());
  }
  return s;
}

Status MDB::DelInfo(const DirId& id, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirMetaType);
#else
  Key key(id.reg, id.snap, id.ino, kDirMetaType);
#endif
  if (tx == NULL) {
    WriteOptions options;
    options.sync = options_.sync;
    s = db_->Delete(options, key.prefix());
  } else {
    tx->batch.Delete(key.prefix());
  }
  return s;
}

Status MDB::DelNode(const DirId& id, const Slice& hash, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirEntType);
#else
  Key key(id.reg, id.snap, id.ino, kDirEntType);
#endif
  key.SetHash(hash);
  if (tx == NULL) {
    WriteOptions options;
    options.sync = options_.sync;
    s = db_->Delete(options, key.Encode());
  } else {
    tx->batch.Delete(key.Encode());
  }
  return s;
}

int MDB::List(const DirId& id, StatList* stats, NameList* names, Tx* tx) {
#if !defined(DELTAFS)
  Key key(id.ino, kDirEntType);
#else
  Key key(id.reg, id.snap, id.ino, kDirEntType);
#endif
  ReadOptions options;
  options.verify_checksums = options_.verify_checksums;
  options.fill_cache = false;
  if (tx != NULL) {
    options.snapshot = tx->snap;
  }
  Slice prefix = key.prefix();
  Iterator* iter = db_->NewIterator(options);
  iter->Seek(prefix);
  Slice name;
  Stat stat;
  int num_entries = 0;
  for (; iter->Valid(); iter->Next()) {
    Slice key = iter->key();
    if (key.starts_with(prefix)) {
      Slice input = iter->value();
      if (stat.DecodeFrom(&input) && GetLengthPrefixedSlice(&input, &name)) {
        if (stats != NULL) {
          stats->push_back(stat);
        }
        if (names != NULL) {
          names->push_back(name.ToString());
        }
        num_entries++;
      }
    } else {
      break;
    }
  }
  delete iter;
  return num_entries;
}

bool MDB::Exists(const DirId& id, const Slice& hash, Tx* tx) {
  Status s;
#if !defined(DELTAFS)
  Key key(id.ino, kDirEntType);
#else
  Key key(id.reg, id.snap, id.ino, kDirEntType);
#endif
  key.SetHash(hash);
  ReadOptions options;
  options.verify_checksums = options_.verify_checksums;
  options.limit = 0;
  if (tx != NULL) {
    options.snapshot = tx->snap;
  }
  Slice ignored;
  char tmp[1];
  s = db_->Get(options, key.Encode(), &ignored, tmp, sizeof(tmp));
  return s.ok();
}

}  // namespace pdlfs
