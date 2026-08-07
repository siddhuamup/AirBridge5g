GO_CORE := ./core/go
RUST_HOTPATH := ./core/rust/securemesh_hotpath
FLUTTER_APP := ./apps/airbridge_5g

.PHONY: go-test rust-test flutter-analyze proto-note

go-test:
	cd $(GO_CORE) && go test ./...

rust-test:
	cd $(RUST_HOTPATH) && cargo test

flutter-analyze:
	cd $(FLUTTER_APP) && flutter analyze

proto-note:
	@echo "Generate protobuf clients after choosing buf/protoc plugins for Go and Dart."
