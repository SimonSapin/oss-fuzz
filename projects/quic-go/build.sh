#!/bin/bash
# Copyright 2020 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

set -ex

function compile_fuzzer {
  path=$1
  function=$2
  fuzzer=$3

  # Compile and instrument all Go files relevant to this fuzz target.
  go-fuzz -func $function -o $fuzzer.a $path

  # Link Go code ($fuzzer.a) with fuzzing engine to produce fuzz target binary.
  $CXX $CXXFLAGS $LIB_FUZZING_ENGINE $fuzzer.a -o $OUT/$fuzzer
}

# Fuzz qpack
compile_fuzzer github.com/marten-seemann/qpack/fuzzing Fuzz qpack_fuzzer

# Fuzz quic-go
compile_fuzzer github.com/lucas-clemente/quic-go/fuzzing/frames Fuzz frame_fuzzer
compile_fuzzer github.com/lucas-clemente/quic-go/fuzzing/header Fuzz header_fuzzer
compile_fuzzer github.com/lucas-clemente/quic-go/fuzzing/transportparameters Fuzz transportparameter_fuzzer
compile_fuzzer github.com/lucas-clemente/quic-go/fuzzing/tokens Fuzz token_fuzzer
compile_fuzzer github.com/lucas-clemente/quic-go/fuzzing/handshake Fuzz handshake_fuzzer

# generate seed corpora
go generate $GOPATH/src/github.com/lucas-clemente/quic-go/fuzzing/...

zip --quiet -r $OUT/header_fuzzer_seed_corpus.zip $GOPATH/src/github.com/lucas-clemente/quic-go/fuzzing/header/corpus
zip --quiet -r $OUT/frame_fuzzer_seed_corpus.zip $GOPATH/src/github.com/lucas-clemente/quic-go/fuzzing/frames/corpus
zip --quiet -r $OUT/transportparameter_fuzzer_seed_corpus.zip $GOPATH/src/github.com/lucas-clemente/quic-go/fuzzing/transportparameters/corpus
zip --quiet -r $OUT/handshake_fuzzer_seed_corpus.zip $GOPATH/src/github.com/lucas-clemente/quic-go/fuzzing/handshake/corpus

# for debugging
ls -al $OUT
