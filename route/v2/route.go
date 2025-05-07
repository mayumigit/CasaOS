package v2

import (
	"github.com/mayumigit/CasaOS/codegen"
	"github.com/mayumigit/CasaOS/service"
)

type CasaOS struct {
	fileUploadService *service.FileUploadService
}

func NewCasaOS() codegen.ServerInterface {
	return &CasaOS{
		fileUploadService: service.NewFileUploadService(),
	}
}
