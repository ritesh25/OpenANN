from libcpp cimport bool
from libcpp.string cimport string
from cython.operator cimport dereference as deref
import numpy


cdef extern from "OpenANN/optimization/StoppingCriteria.h" namespace "OpenANN":
  ctypedef struct c_StoppingCriteria "OpenANN::StoppingCriteria":
    int maximalFunctionEvaluations
    int maximalIterations
    int maximalRestarts
    float minimalValue # TODO configure
    float minimalValueDifferences # TODO configure
    float minimalSearchSpaceStep # TODO configure
  c_StoppingCriteria *new_StoppingCriteria "new OpenANN::StoppingCriteria" ()
  void del_StoppingCriteria "delete" (c_StoppingCriteria *ptr)


cdef extern from "OpenANN/ActivationFunctions.h" namespace "OpenANN":
  cdef enum c_ActivationFunction "OpenANN::ActivationFunction":
    LOGISTIC
    TANH
    TANH_SCALED
    RECTIFIER
    LINEAR

cdef extern from "Eigen/Dense" namespace "Eigen":
  ctypedef struct c_VectorXf "Eigen::VectorXf":
    float* data()
    int rows()
    float& get "operator()"(int rows)
  c_VectorXf *new_VectorXf "new Eigen::VectorXf" (c_VectorXf& vec)
  c_VectorXf *new_VectorXf "new Eigen::VectorXf" (int rows, int cols)
  void del_VectorXf "delete" (c_VectorXf *ptr)

  ctypedef struct c_MatrixXf "Eigen::MatrixXf":
    float& coeff(int row, int col)
    float* data()
    int rows()
    int cols()
    float& get "operator()"(int rows, int cols)
  c_MatrixXf *new_MatrixXf "new Eigen::MatrixXf" (int rows, int cols)
  void del_MatrixXf "delete" (c_MatrixXf *ptr)

  ctypedef struct c_VectorXd "Eigen::VectorXd":
    double* data()
    int rows()
    double& get "operator()"(int rows)
  c_VectorXd *new_VectorXd "new Eigen::VectorXd" (c_VectorXd& vec)
  c_VectorXd *new_VectorXd "new Eigen::VectorXd" (int rows, int cols)
  void del_VectorXd "delete" (c_VectorXd *ptr)

  ctypedef struct c_MatrixXd "Eigen::MatrixXd":
    double& coeff(int row, int col)
    double* data()
    int rows()
    int cols()
    double& get "operator()"(int rows, int cols)
  c_MatrixXd *new_MatrixXd "new Eigen::MatrixXd" (int rows, int cols)
  void del_MatrixXd "delete" (c_MatrixXd *ptr)

cdef extern from "OpenANN/Learner.h" namespace "OpenANN":
  ctypedef struct c_Learner "OpenANN::Learner"

cdef extern from "OpenANN/DeepNetwork.h" namespace "OpenANN":
  cdef enum c_ErrorFunction "OpenANN::ErrorFunction":
    NO_E_DEFINED
    SSE
    MSE
    CE
  cdef enum c_Training "OpenANN::Training":
    NOT_INITIALIZED
    BATCH_CMAES
    BATCH_LMA
    BATCH_SGD
    MINIBATCH_SGD

cdef extern from "OpenANN/DeepNetwork.h" namespace "OpenANN":
  ctypedef struct c_DeepNetwork "OpenANN::DeepNetwork":
    c_DeepNetwork& inputLayer(int dim1, int dim2, int dim3, bool bias,
                              float dropoutProbability) # TODO configure
    c_DeepNetwork& alphaBetaFilterLayer(float deltaT, float stdDev, bool bias) # TODO configure
    c_DeepNetwork& fullyConnectedLayer(int units, c_ActivationFunction act,
                                       float stdDev, bool bias,
                                       float dropoutProbability) # TODO configure
    c_DeepNetwork& compressedLayer(int units, int params, c_ActivationFunction act,
                                   string compression, float stdDev,
                                   bool bias, float dropoutProbability) # TODO configure
    c_DeepNetwork& convolutionalLayer(int featureMaps, int kernelRows,
                                      int kernelCols, c_ActivationFunction act,
                                      float stdDev, bool bias) # TODO configure
    c_DeepNetwork& subsamplingLayer(int kernelRows, int kernelCols,
                                    c_ActivationFunction act, float stdDev,
                                    bool bias) # TODO configure
    c_DeepNetwork& maxPoolingLayer(int kernelRows, int kernelCols, bool bias)
    c_DeepNetwork& outputLayer(int units, c_ActivationFunction act, float stdDev) # TODO configure
    c_DeepNetwork& compressedOutputLayer(int units, int params,
                                         c_ActivationFunction act,
                                         string& compression, float stdDev) # TODO configure
    c_Learner& trainingSet(c_MatrixXf& trainingInput, c_MatrixXf& trainingOutput) # TODO configure
    c_VectorXf train(c_Training algorithm, c_ErrorFunction errorFunction, # TODO configure
                     c_StoppingCriteria stop, bool reinitialize, bool dropout)
    c_VectorXf predict "operator()"(c_VectorXf x) # TODO configure
  c_DeepNetwork *new_DeepNetwork "new OpenANN::DeepNetwork" ()
  void del_DeepNetwork "delete" (c_DeepNetwork *ptr)

cdef class DeepNetwork:
  cdef c_DeepNetwork *thisptr,
  # TODO destroy ptrs on replacement
  cdef c_MatrixXf *inptr # TODO configure
  cdef c_MatrixXf *outptr # TODO configure
  cdef c_StoppingCriteria *stop
  cdef c_VectorXf *xptr # TODO configure
  cdef c_VectorXf *yptr # TODO configure

  def __cinit__(self):
    self.thisptr = new_DeepNetwork()
    self.stop = new_StoppingCriteria()

  def __dealloc__(self):
    del_DeepNetwork(self.thisptr)
    del_MatrixXf(self.inptr)
    del_MatrixXf(self.outptr)
    del_StoppingCriteria(self.stop)
    del_VectorXf(self.xptr)

  def __get_dims(self, shape, max_dim):
    shape_array = numpy.asarray(shape).flatten()
    assert len(shape_array) in range(1, 1+max_dim)
    dims = numpy.append(shape_array, numpy.ones(max_dim-len(shape_array)))
    return dims

  def __get_activation_function(self, act):
    return {"logistic" : LOGISTIC,
            "tanh" : TANH,
            "tanhscaled" : TANH_SCALED,
            "rectifier" : RECTIFIER,
            "linear" : LINEAR}[act]

  def __get_error_function(self, err):
    return {"sse" : SSE,
            "mse" : MSE,
            "ce" : CE}[err]

  def __get_training(self, training):
    return {"lma" : BATCH_LMA,
            "sgd" : BATCH_SGD,
            "cmaes" : BATCH_CMAES,
            "mbsgd" : MINIBATCH_SGD}[training]

  def input_layer(self, shape, bias=True, dropout_probability=0.0):
    dims = self.__get_dims(shape, 3)
    self.thisptr.inputLayer(dims[0], dims[1], dims[2], bias, dropout_probability)
    return self

  def alpha_beta_filter_layer(self, delta_t, std_dev=0.05, bias=True):
    self.thisptr.alphaBetaFilterLayer(delta_t, std_dev, bias)
    return self

  def fully_connected_layer(self, units, act, std_dev=0.05, bias=True, dropout_probability=0.0):
    self.thisptr.fullyConnectedLayer(units, self.__get_activation_function(act),
                                     std_dev, bias, dropout_probability)
    return self

  def compressed_layer(self, units, params, act, compression, std_dev=0.05,
                       bias=True, dropout_probability=0.0):
    cdef char* comp = compression
    self.thisptr.compressedLayer(units, params, self.__get_activation_function(act),
                                 string(comp), std_dev, bias, dropout_probability)
    return self

  def convolutional_layer(self, featureMaps, kernelRows, kernelCols, act,
                          std_dev=0.05, bias=True):
    self.thisptr.convolutionalLayer(featureMaps, kernelRows, kernelCols,
                                    self.__get_activation_function(act),
                                    std_dev, bias)
    return self

  def subsampling_layer(self, kernelRows, kernelCols, act, std_dev=0.05,
                        bias=True):
    self.thisptr.subsamplingLayer(kernelRows, kernelCols,
                                  self.__get_activation_function(act),
                                  std_dev, bias)
    return self

  def maxpooling_layer(self, kernelRows, kernelCols, bias=True):
    self.thisptr.maxPoolingLayer(kernelRows, kernelCols, bias)
    return self

  def output_layer(self, units, act, std_dev=0.05):
    self.thisptr.outputLayer(units, self.__get_activation_function(act), std_dev)
    return self

  def compressed_output_layer(self, units, params, act, compression, std_dev=0.05):
    cdef char* comp = compression
    self.thisptr.compressedOutputLayer(units, params,
                                       self.__get_activation_function(act),
                                       string(comp), std_dev)
    return self

  def training_set(self, inputs, outputs):
    assert inputs.shape[1] == outputs.shape[1]
    self.inptr = new_MatrixXf(inputs.shape[0], inputs.shape[1])
    self.outptr = new_MatrixXf(outputs.shape[0], outputs.shape[1])
    self.__numpy_to_eigen_train(inputs, outputs)
    self.thisptr.trainingSet(deref(self.inptr), deref(self.outptr))
    return self

  def __numpy_to_eigen_train(self, num_in, num_out):
    rows = num_in.shape[0]
    cols = num_in.shape[1]
    idx = 0
    for r in range(rows):
      for c in range(cols):
        self.inptr.data()[idx] = num_in[r, c]
        idx += 1
    rows = num_out.shape[0]
    cols = num_out.shape[1]
    idx = 0
    for r in range(rows):
      for c in range(cols):
        self.outptr.data()[idx] = num_out[r, c]
        idx += 1

  def __stop_dict(self):
    return {"maximalFunctionEvaluations" : self.stop.maximalFunctionEvaluations,
            "maximalIterations" : self.stop.maximalIterations,
            "maximalRestarts" : self.stop.maximalRestarts,
            "minimalValue" : self.stop.minimalValue,
            "minimalValueDifferences" : self.stop.minimalValueDifferences,
            "minimalSearchSpaceStep" : self.stop.minimalSearchSpaceStep}

  def __stop_from_dict(self, d):
    self.stop.maximalFunctionEvaluations = d.get("maximalFunctionEvaluations",
        self.stop.maximalFunctionEvaluations)
    self.stop.maximalIterations = d.get("maximalIterations",
        self.stop.maximalIterations)
    self.stop.maximalRestarts = d.get("maximalRestarts",
        self.stop.maximalRestarts)
    self.stop.minimalValue = d.get("minimalValue", self.stop.minimalValue)
    self.stop.minimalValueDifferences = d.get("minimalValueDifferences",
        self.stop.minimalValueDifferences)
    self.stop.minimalSearchSpaceStep = d.get("minimalSearchSpaceStep",
        self.stop.minimalSearchSpaceStep)

  def train(self, algorithm, err, stop, reinitialize=True, dropout=False):
    self.__stop_from_dict(stop)
    self.thisptr.train(self.__get_training(algorithm),
                       self.__get_error_function(err), deref(self.stop),
                       reinitialize, dropout)

  def predict(self, X):
    if len(X.shape) == 2:
      Y = []
      for i in range(X.shape[1]):
        Y.append(self.__predict(X[:, i]))
      return numpy.asarray(Y).T
    else:
      return self.__predict(X)

  def __predict(self, x):
    self.__numpy_to_eigen_input(x)
    self.yptr = new_VectorXf(self.thisptr.predict(deref(self.xptr)))
    return self.__eigen_to_numpy_output()

  def __numpy_to_eigen_input(self, x):
    self.xptr = new_VectorXf(x.shape[0], 1) # TODO configure
    rows = x.shape[0]
    for r in range(rows):
      self.xptr.data()[r] = x[r]

  def __eigen_to_numpy_output(self):
    cdef int rows = self.yptr.rows()
    y = numpy.ndarray((rows,))
    for r in range(rows):
      y[r] = self.yptr.data()[r]
    return y


