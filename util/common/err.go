package common

import (
	"errors"
	"fmt"
	"xui/logger"
)

var CtxDone = errors.New("context done")

func NewErrorf(format string, a ...interface{}) error {
	msg := fmt.Sprintf(format, a...)
	return errors.New(msg)
}

func NewError(a ...interface{}) error {
	msg := fmt.Sprintln(a...)
	return errors.New(msg)
}

func Recover(msg string) interface{} {
	panicErr := recover()
	if panicErr != nil {
		if msg != "" {
			logger.Error(msg, "panic:", panicErr)
		}
	}
	return panicErr
}
