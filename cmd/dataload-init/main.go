package main

import (
	"context"
	"flag"
	"fmt"
	datastorev1alpha1 "github.com/hwameistor/datastore/pkg/apis/client/clientset/versioned/typed/datastore/v1alpha1"
	datastore "github.com/hwameistor/datastore/pkg/apis/datastore/v1alpha1"
	log "github.com/sirupsen/logrus"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/rand"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes"
	v1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/rest"
	"os"
	"time"
)

var (
	nodeName = flag.String("nodename", "", "Node name")
	dstDir   = flag.String("dstdir", "", "destination Directory")
)

const (
	NameSpaceEnvVar = "NAMESPACE"
	pvcNameEnvVar   = "PVC_NAME"
	apiGroup        = "example.com"
	version         = "v1alpha1"
)

func main() {
	flag.Parse()
	if *nodeName == "" {
		log.WithFields(log.Fields{"nodename": *nodeName}).Error("Invalid node name")
		os.Exit(1)
	}

	namespace := os.Getenv(NameSpaceEnvVar)
	pvcName := os.Getenv(pvcNameEnvVar)

	if namespace == "" || pvcName == "" {
		log.Fatal("Namespace or PVC Name environment variables are not set.")
		os.Exit(1)
	}

	config, err := getConfig()
	if err != nil {
		log.WithError(err).Fatal("Failed to get Kubernetes configuration")
		os.Exit(1)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.WithError(err).Fatal("Failed to create Kubernetes clientset")
		os.Exit(1)
	}

	pvcClient := clientset.CoreV1().PersistentVolumeClaims(namespace)
	pvc, err := getPersistentVolumeClaim(pvcClient, pvcName)
	if err != nil {
		log.WithError(err).Error("Failed to get PVC")
		os.Exit(1)
	}

	dataSetName := pvc.Spec.VolumeName
	dataLoadRequestName := dataSetName + "-" + generateRandomSuffix()
	dataLoadRequest := createDataLoadRequest(dataLoadRequestName, dataSetName)
	if *dstDir != "" {
		dataLoadRequest.Spec.DstDir = *dstDir
	}
	dsClient, err := datastorev1alpha1.NewForConfig(config)
	watcher, err := watchCustomResource(dsClient, namespace, dataLoadRequestName)
	if err != nil {
		log.WithError(err).Error("Failed to start watching custom resource")
		os.Exit(1)
	}
	defer watcher.Stop()
	start := time.Now()
	if err := createCustomResource(dsClient, dataLoadRequest, namespace); err != nil {
		log.WithError(err).Error("Failed to create custom resource")
		os.Exit(1)
	}
	fmt.Println("Created custom resource")
	for event := range watcher.ResultChan() {
		if event.Type == watch.Deleted {
			fmt.Println("Custom resource deleted, exiting")
			end := time.Now()
			duration := end.Sub(start)
			fmt.Printf("DataLoad execution time: %s\n", duration)
			return
		}
	}
}

func getConfig() (*rest.Config, error) {
	config, err := rest.InClusterConfig()
	if err != nil {
		return nil, fmt.Errorf("failed to get in-cluster config: %w", err)
	}
	return config, nil
}

func getPersistentVolumeClaim(pvcClient v1.PersistentVolumeClaimInterface, pvcName string) (*corev1.PersistentVolumeClaim, error) {
	return pvcClient.Get(context.TODO(), pvcName, metav1.GetOptions{})
}

func createDataLoadRequest(dataLoadRequestName, dataSetName string) *datastore.DataLoadRequest {
	return &datastore.DataLoadRequest{
		TypeMeta: metav1.TypeMeta{
			APIVersion: fmt.Sprintf("%s/%s", apiGroup, version),
			Kind:       "DataLoadRequest",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name: dataLoadRequestName,
		},
		Spec: datastore.DataLoadRequestSpec{
			IsGlobal: true,
			Node:     *nodeName,
			DataSet:  dataSetName,
		},
		Status: datastore.DataLoadRequestStatus{
			State: datastore.OperationStateStart,
		},
	}
}

func createCustomResource(dsClient datastorev1alpha1.DatastoreV1alpha1Interface, dataLoadRequest *datastore.DataLoadRequest, namespace string) error {
	_, err := dsClient.DataLoadRequests(namespace).Create(context.Background(), dataLoadRequest, metav1.CreateOptions{})
	if err != nil && !errors.IsAlreadyExists(err) {
		return fmt.Errorf("failed to create custom resource: %w", err)
	}
	return nil
}

func watchCustomResource(dsClient datastorev1alpha1.DatastoreV1alpha1Interface, namespace, resourceName string) (watch.Interface, error) {
	return dsClient.DataLoadRequests(namespace).Watch(context.TODO(), metav1.ListOptions{
		FieldSelector: fmt.Sprintf("metadata.name=%s", resourceName),
	})
}

func generateRandomSuffix() string {
	return rand.String(5)
}