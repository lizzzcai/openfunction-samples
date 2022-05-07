package events_handler_function

import (
	"encoding/json"
	"fmt"

	ofctx "github.com/OpenFunction/functions-framework-go/context"
	"github.com/minio/minio-go/v7/pkg/notification"
)

const (
	EventName   = "s3:ObjectCreated:Put"
	ContentType = "image/png"
)

type Event struct {
	EventName string               `json:"EventName"`
	Key       string               `json:"Key"`
	Records   []notification.Event `json:"Records"`
}

func EventsHandler(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	fmt.Println(string(in))
	event := Event{}
	json.Unmarshal(in, &event)
	fmt.Println(event)

	if event.EventName == EventName {
		fmt.Printf("event name is %s\n", EventName)
	}

	return ctx.ReturnOnSuccess(), nil
}
