package main

import (
	"context"
	"flag"
	"os"

	"github.com/hwameistor/datastore/pkg/utils"
	"github.com/kubernetes-csi/csi-lib-utils/leaderelection"
	"github.com/operator-framework/operator-sdk/pkg/k8sutil"
	log "github.com/sirupsen/logrus"

	metadatacontroller "github.com/hwameistor/datastore/pkg/metadata-controller"
)

const (
	lockName = "datastore-metadata-controller"
)

var (
	namespace = flag.String("namespace", "", "Namespace of the Pod")
)

func setupLogging() {
	log.SetLevel(log.DebugLevel)
}

func main() {
	flag.Parse()
	setupLogging()

	stopCh := make(chan struct{})
	run := func(ctx context.Context) {
		if err := metadatacontroller.NewMetadataController(*namespace).Run(stopCh); err != nil {
			log.WithFields(log.Fields{"error": err.Error()}).Error("failed to run metadata controller")
			os.Exit(1)
		}
	}

	le := leaderelection.NewLeaderElection(utils.BuildInClusterClientset(), lockName, run)
	opNamespace, _ := k8sutil.GetOperatorNamespace()
	le.WithNamespace(opNamespace)

	if err := le.Run(); err != nil {
		stopCh <- struct{}{}
		log.Fatalf("failed to initialize leader election: %v", err)
	}

}
